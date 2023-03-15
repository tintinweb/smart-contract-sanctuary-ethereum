/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
 * @dev Keeps all the operations data for the deployed Seasteads
 * as keeping these information makes the Seastead Contract avoid the size limit
 */
contract Operations {
    struct Operator {
        address payable wallet;
        address payable[] seasteadAddresses;
        bool active;
        string name;
        // mapping(address => SeasteadUnit) seasteads;
    }

    struct SeasteadUnit {
        address payable operator;
        uint8 monthsPassed;
        uint8 revShare;
        uint8 ticketedMonths;
        uint16 placement;
        uint32 estMonthlyRev;
        uint32 minMonthlyDue;
        uint48 nextMonthDue;
        uint48 ticketsBurned;
        uint48 totalPenalty;
        uint64 totalObligation;
        uint256 timeStamp;
    }

    uint8 public constant penalty = 2;
    mapping(address => Operator) public operators;
    mapping(address => SeasteadUnit) public seasteads;

    /**
     * @dev adds an operator to this contract
     * @param _wallet the address of the operator's wallet
     * @param _name the operator's name
     */
    function addOperator(address _wallet, string calldata _name) external {
        Operator storage newOperator = operators[_wallet];
        newOperator.name = _name;
        newOperator.wallet = payable(_wallet);
        newOperator.active = true;
    }

    /**
     * @dev assigns a seastead to an operator
     * @param _revShare the % of the revenue share agreed by the operator
     * @param _ticketedMonths the number of ticketed months agreed by the operator
     * @param _placement the seastead locaion code
     * @param _minMonthlyDue the minimum monthly revenue payment by the operator
     * @param _estRev the estimated monthly revenue
     * @param _operator the name of the seastead operator
     */
    function assignOperator(
        address payable seasteadAddress,
        uint8 _revShare,
        uint8 _ticketedMonths,
        uint16 _placement,
        uint32 _minMonthlyDue,
        uint32 _estRev,
        address _operator
    ) external returns (bool) {
        Operator storage selectedOperator = operators[_operator];
        require(selectedOperator.active == true, "408");
        seasteads[seasteadAddress] = SeasteadUnit({
            operator: payable(_operator),
            monthsPassed: 0,
            revShare: _revShare,
            ticketedMonths: _ticketedMonths,
            placement: _placement,
            estMonthlyRev: _estRev,
            minMonthlyDue: _minMonthlyDue * (10 ** 6),
            nextMonthDue: _minMonthlyDue * (10 ** 6),
            ticketsBurned: 0,
            totalPenalty: 0,
            totalObligation: _minMonthlyDue * _ticketedMonths,
            timeStamp: block.timestamp
        });
        selectedOperator.seasteadAddresses.push(seasteadAddress);
        return true;
    }

    /**
     * @dev converting the _amount to equivalent tokens to pay
     * @param _marketplacePrice the current marketplace rate
     * @param _seasteadAddress the target seastead's address.
     * @return uint48 the number of tokens
     */
    function determineTokens(
        uint48 _marketplacePrice,
        address _seasteadAddress
    ) external view returns (uint48) {
        uint48 _amount = seasteads[_seasteadAddress].nextMonthDue;
        return uint48((uint64(_amount) * (10 ** 6)) / _marketplacePrice);
    }

    function getSeasteads(
        address _operator
    ) external view returns (address payable[] memory) {
        Operator storage op = operators[_operator];
        return op.seasteadAddresses;
    }

    /**
     * @dev allows the operator to settle their (monthly) dues
     * @param _operator the designated operator
     * @param _seastead the seastead address to settle on
     * @param _amount the equivalent amount from the steadTokens burned
     * @param _steadTokens the steadTokens burned
     */
    function payDues(
        address _operator,
        address _seastead,
        uint48 _amount,
        uint48 _steadTokens
    ) external returns (bool) {
        Operator storage selectedOperator = operators[_operator];
        require(selectedOperator.active == true, "408");
        // SeasteadUnit storage targetSeastead = selectedOperator.seasteads[
        //     _seastead
        // ];
        SeasteadUnit storage targetSeastead = seasteads[_seastead];
        require(targetSeastead.ticketedMonths > 0, "412");

        uint48 currentDue = targetSeastead.minMonthlyDue >=
            targetSeastead.nextMonthDue
            ? targetSeastead.minMonthlyDue
            : targetSeastead.nextMonthDue;

        if (_amount >= currentDue) {
            _settleWithCredits(targetSeastead, currentDue, _amount);
        } else {
            // Settle with payment less than the current due:
            _settleWithPenalty(targetSeastead, currentDue, _amount);
        }

        targetSeastead.ticketsBurned += _steadTokens;
        return true;
    }

    /**
     * @dev updates the totalPenalty via Chainlink Upkeep
     * _monthsPassed has to be within the ticketMonths
     * 2% Penalty is non-compounding - fix monthly rate
     */
    function updatePenalty(address _operator, address _seastead) external {
        Operator storage selectedOperator = operators[_operator];
        require(selectedOperator.active == true, "408");
        // SeasteadUnit storage targetSeastead = selectedOperator.seasteads[
        //     _seastead
        // ];
        SeasteadUnit storage targetSeastead = seasteads[_seastead];
        require(
            targetSeastead.monthsPassed <= targetSeastead.ticketedMonths,
            "406"
        );
        require(
            block.timestamp >=
                (targetSeastead.timeStamp +
                    (targetSeastead.monthsPassed * 2592000)),
            "407"
        );
        // fixed-rate, non-compounding
        targetSeastead.totalPenalty +=
            (targetSeastead.minMonthlyDue * penalty) /
            100;
        // include the total penalty to next month's due:
        targetSeastead.nextMonthDue += targetSeastead.totalPenalty;
        ++targetSeastead.monthsPassed;
    }

    /**
     * @dev effectively cancels the seastead operations
     * @param _operator address of the assigned operator
     */
    function voidOperations(address _operator) external returns (bool) {
        Operator storage selectedOperator = operators[_operator];
        require(selectedOperator.active == true, "408");
        bool success = false;
        selectedOperator.active = false;
        success = true;
        return success;
    }

    /**
     * @dev Are we going to give credits for advanced payments? How so? 28 Feb 2023
     * If I pay extra then I pay off future 'months' but still have a payment due next month,
     * if I do not pay enough this month then my remaining amount gets added to the penalties.
     * Mitchell: 01 Mar 2023
     */
    function _settleWithCredits(
        SeasteadUnit storage _seastead,
        uint48 _currentDue,
        uint48 _amount
    ) internal {
        if (_amount > _currentDue) _amount = _amount - _currentDue;
        // total penalty is included in the current due:
        _seastead.totalPenalty = 0;

        if (_amount > _seastead.minMonthlyDue) {
            uint48 remainingCredits = _amount % _seastead.minMonthlyDue;
            uint8 advancedMonths = uint8(
                (_amount - remainingCredits) / _seastead.minMonthlyDue
            );
            // Pay off the future months:
            if (advancedMonths > 1)
                _seastead.ticketedMonths -= (advancedMonths + 1); // + 1 to account for round-offs
            else if (advancedMonths == 1) --_seastead.ticketedMonths;
            // Update next month's credit:
            _seastead.nextMonthDue = _seastead.minMonthlyDue - remainingCredits;
        } else {
            _seastead.nextMonthDue = _seastead.minMonthlyDue - _amount;
        }
    }

    /**
     * @dev payment option whenever there is penalty and the payment is
     * less than the total due
     */
    function _settleWithPenalty(
        SeasteadUnit storage _seastead,
        uint48 _currentDue,
        uint48 _amount
    ) internal {
        // Payment < totalPenalty
        if (_seastead.totalPenalty >= _amount) {
            _seastead.totalPenalty -= _amount;
            _seastead.nextMonthDue = _currentDue - _amount;
        } else {
            // Settle the penalty first:
            _amount = _amount - _seastead.totalPenalty;
            _seastead.totalPenalty = 0;
            _seastead.nextMonthDue = _amount;
        }
    }
}