// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "ReentrancyGuard.sol";
import "Pensioner.sol";

/// @title A representation of a pension system
/// @author Alvaro SÃ¡nchez GarcÃ­a
/// @dev This contract is intended to be run with Pensioner.sol
/// @dev The use of a PROPORTION_FACTOR is to workaround the non existance of floating numbers
/// @notice All timestamps are expressed using Unix time https://en.wikipedia.org/wiki/Unix_time
/// @notice All durations are expressed in seconds
contract PensionSystem is ReentrancyGuard {
    mapping(address => Pensioner) public pensioners;
    mapping(address => uint8) public isPensionerCreated;
    address payable[] public pensionerList;
    uint256 public createdAtTime;
    uint256 public lastPayoutDate;
    uint256 public payoutInterval;

    mapping(address => uint256) private _pensionerAmount;
    address[] private _pensioners;

    /// @notice Creates a pension system
    /// @param _payoutInterval The interval at which the payouts will roll out
    constructor(uint256 _payoutInterval) public ReentrancyGuard() {
        createdAtTime = block.timestamp;
        lastPayoutDate = createdAtTime;
        payoutInterval = _payoutInterval;
    }

    /// @notice Creates a pensioner
    /// @dev The address must not be already registered
    /// @dev The retirementTime must be a future date
    /// @param retirementTime Timestamp at which the new pensioner wants to retire
    /// @param benefitDuration Duration during which a retired pensioner will be eligible for benefits
    function createPensioner(uint256 retirementTime, uint256 benefitDuration)
        public
    {
        require(
            retirementTime >= block.timestamp,
            "Can not retire before creating the account"
        );
        require(
            isPensionerCreated[msg.sender] == 0,
            "Pensioner already exists"
        );
        Pensioner pensioner = new Pensioner(retirementTime, benefitDuration);
        pensioners[msg.sender] = pensioner;
        isPensionerCreated[msg.sender] = 1;
        pensionerList.push(msg.sender);
    }

    /// @notice Changes a pensioner retirement time
    /// @dev The pensioner must exist
    /// @dev The date of retirement must be a future one
    /// @dev The pensioner must not be retired
    function setRetirementTime(uint256 retireDate) public {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        require(retireDate >= block.timestamp, "Date must be a future one");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Pensioner cannot retire after being retired"
        );
        pensioners[msg.sender].setRetirement(retireDate);
    }

    /// @notice Changes a pensioner retirement time for now
    /// @dev The pensioner must exist
    /// @dev The pensioner must not be retired
    function setRetirementTimeNow() public {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Pensioner cannot retire after being retired"
        );
        pensioners[msg.sender].setRetirementNow();
    }

    /// @notice Changes a pensioner benefit duration
    /// @dev The pensioner must exist
    /// @dev The pensioner must not be retired
    function setBenefitDuration(uint256 benefitDuration) public {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Pensioner cannot retire after being retired"
        );
        pensioners[msg.sender].setBenefitDuration(benefitDuration);
    }

    /// @notice Adds an amount to the pension attributable to a pensioner
    /// @dev The pensioner must exist
    /// @dev The pensioner must not be retired
    function fundPension() public payable {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Cannot contribute to a retired account"
        );
        pensioner.addContribution(msg.value);
    }

    /// @notice Calculates the state of the pension system
    /// @notice Pays the pensions to the elegible pensioners
    /// @dev The pensioner must be retired
    /// @dev The pensioner must have an active benefit window
    /// @dev The pensioner must have funded the system
    function calculateState() public nonReentrant {
        if (lastPayoutDate + payoutInterval > block.timestamp) {
            return;
        } else {
            lastPayoutDate = block.timestamp;
        }
        uint256 agreggatedContributions = 0;
        uint256 totalToBeDistributed = getTotalToBeDistributed();

        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            if (
                pensioner.isPensionerRetired() &&
                pensioner.isInsideBenefitDuration() &&
                pensioner.totalContributedAmount() > 0
            ) {
                agreggatedContributions += pensioner.getWeightedContribution();
            }
        }

        uint256 totalSplitPayout = 0;
        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            if (
                pensioner.isPensionerRetired() &&
                pensioner.isInsideBenefitDuration() &&
                pensioner.totalContributedAmount() > 0
            ) {
                uint256 pensionerPayout = 0;
                if (i == pensionerList.length - 1) {
                    pensionerPayout = totalToBeDistributed - totalSplitPayout;
                } else {
                    uint256 contributedByPensioner = pensioner
                        .getWeightedContribution();
                    pensionerPayout =
                        (contributedByPensioner * totalToBeDistributed) /
                        agreggatedContributions;
                    totalSplitPayout += pensionerPayout;
                }

                _pensioners.push(pensionerAdd);
                _pensionerAmount[pensionerAdd] = pensionerPayout;
            }
        }

        for (uint256 i = 0; i < _pensioners.length; i++) {
            address pensionerAdd = _pensioners[i];
            uint256 amount = _pensionerAmount[pensionerAdd];
            payable(pensionerAdd).transfer(amount);
            delete _pensionerAmount[pensionerAdd];
        }
        delete _pensioners;
    }

    /// @notice Returns the mapping of pensioners in 2 separate arrays, one for address and another for
    /// @notice pensioner address
    /// @dev It is a workaround since we cannot return a mapping directly
    function getPensionerList()
        public
        view
        returns (address[] memory, Pensioner[] memory)
    {
        address[] memory mAddresses = new address[](pensionerList.length);
        Pensioner[] memory mPensioners = new Pensioner[](pensionerList.length);
        for (uint256 i = 0; i < pensionerList.length; i++) {
            mAddresses[i] = pensionerList[i];
            mPensioners[i] = pensioners[pensionerList[i]];
        }
        return (mAddresses, mPensioners);
    }

    /// @notice Calculates the total to be distributed based on the ratio of pensioners and contributors
    /// @dev Only takes into account active pensioners and active contributors
    /// @dev The value is given by the formula (lambda * (balance * 0.90))
    /// @dev Lambda is the ratio
    /// @dev The balance is not 100% given possible gas costs
    function getTotalToBeDistributed() private view returns (uint256) {
        uint256 lambda = 0;
        uint256 numberOfContributors = 0;
        uint256 numberOfPensioners = 0;
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            if (pensioner.isPensionerRetired()) {
                if (pensioner.isInsideBenefitDuration()) {
                    numberOfPensioners++;
                }
            } else if (pensioner.totalContributedAmount() > 0) {
                numberOfContributors++;
            }
        }
        if (numberOfPensioners == 0) {
            return 0;
        }
        if (numberOfContributors == 0) {
            return (balance * 20) / 100;
        }
        if (numberOfContributors > numberOfPensioners) {
            return (balance * 90) / 100;
        }
        lambda = (numberOfContributors * 100) / numberOfPensioners;
        return (((balance * 90) / 100) * lambda) / 100;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/// @title A representation of a pensioner
/// @author Alvaro SÃ¡nchez GarcÃ­a
/// @dev This contract is intended to be run with PensionSystem.sol
/// @notice All timestamps are expressed using Unix time https://en.wikipedia.org/wiki/Unix_time
/// @notice All durations are expressed in seconds
contract Pensioner {
    uint256 public totalContributedAmount;
    uint256 public createdAtTime;
    uint256 public retireAtDate;
    uint256 public benefitDuration;

    /// @notice Creates a pensioner
    /// @param _retireAtDate Timestamp at which the new pensioner wants to retire
    /// @param _benefitDuration Timestamp representing the amount of time the pensioner will be elegible for benefits
    constructor(uint256 _retireAtDate, uint256 _benefitDuration) public {
        totalContributedAmount = 0;
        createdAtTime = block.timestamp;
        retireAtDate = _retireAtDate;
        benefitDuration = _benefitDuration;
    }

    /// @notice Retires a pensioner at the current block timestamp
    function setRetirementNow() public {
        setRetirement(block.timestamp);
    }

    /// @notice Changes a pensioner retirement date
    /// @dev We substract one just in case block.timestamp doesnt change when performing the next operation
    function setRetirement(uint256 retireDate) public {
        require(retireDate >= block.timestamp, "Date must be a future one");
        retireAtDate = retireDate - 1;
    }

    /// @notice Changes a pensioner benefit duration
    function setBenefitDuration(uint256 _benefitDuration) public {
        benefitDuration = _benefitDuration;
    }

    /// @notice Adds a contribution to the total amount contributed by the pensioner
    /// @param amount The new value to be added to the total amount
    function addContribution(uint256 amount) public {
        require(
            !isPensionerRetired(),
            "Pensioner must be active to contribute"
        );
        totalContributedAmount += amount;
    }

    /// @notice Returns the date at which the pensioner will stop receiving funds
    function getFinishPensionTime() public view returns (uint256) {
        return retireAtDate + benefitDuration;
    }

    /// @notice Returns whether a pensioner is retired or not
    function isPensionerRetired() public view returns (bool) {
        return retireAtDate <= block.timestamp;
    }

    /// @notice Returns whether a pension is inside his benefit duration
    function isInsideBenefitDuration() public view returns (bool) {
        return getFinishPensionTime() >= block.timestamp;
    }

    function getWeightedContribution() public view returns (uint256) {
        return totalContributedAmount / benefitDuration;
    }
}