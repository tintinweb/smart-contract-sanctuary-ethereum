// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./SCProcessFlow.sol";

contract Token is SCProcessFlow{
//Data type definition

//Defined state variables
    string bu_id = "BUID_50b842e6";
    uint plannedPaymentAmount = 14;
    uint plannedCompletionDate = 20210711;
    uint actualStartDate;
    uint actualCompletionDate;
    uint actualPayment;
    bool isAgreedStart = false;
    bool isDefect;

//Roles in state variables
    address Contractor = 0xE3F0AE6EB5b6b554779fC15A683491AD98dd8881;
    address payable Client = 0xA7fd862d4eeC188A82d949Cc8EeA142a271F1b41;
    address SubContractor;

//Roles in modifiers
    modifier OnlyContractor(){
        require(msg.sender == Contractor," Only Contractor can call this function.");
        _;
    }
    modifier OnlyClient(){
        require(msg.sender == Client," Only Client can call this function.");
        _;
    }
    modifier OnlySubContractor(){
        require(msg.sender == SubContractor," Only SubContractor can call this function.");
        _;
    }

//Functions
    function BU_C_paid()
        public
        payable
        OnlyClient()
        inProcessFlow(ProcessFlow.ToBU_C_paid)
        returns (uint _actualPayment)
    {
        Client.transfer(actualPayment);
        _actualPayment = actualPayment;
        deleteFlow(ProcessFlow.ToBU_C_paid);
        currentProcessFlows.push(ProcessFlow.ToBU_D_checked);
    }

    function BU_D_checked(bool _isAgreedStart)
        public
        OnlyContractor()
        inProcessFlow(ProcessFlow.ToBU_D_checked)
    {
        isAgreedStart = _isAgreedStart;
        deleteFlow(ProcessFlow.ToBU_D_checked);
        if(isAgreedStart == false)
        {
        }
        else
        {
            currentProcessFlows.push(ProcessFlow.ToBU_started);
        }
    }

    function BU_D_defined(string memory _bu_id, uint _plannedPaymentAmount, uint _plannedCompletionDate)
        public
        OnlyClient()
        inProcessFlow(ProcessFlow.ToBU_D_defined)
    {
        bu_id = _bu_id;
        plannedPaymentAmount = _plannedPaymentAmount;
        plannedCompletionDate = _plannedCompletionDate;
        deleteFlow(ProcessFlow.ToBU_D_defined);
        currentProcessFlows.push(ProcessFlow.ToBU_D_checked);
    }

    function BU_checked_with_defects(bool _isDefect, uint _actualPayment)
        public
        OnlyClient()
        inProcessFlow(ProcessFlow.ToBU_checked_with_defects)
    {
        isDefect = _isDefect;
        actualPayment = _actualPayment;
        deleteFlow(ProcessFlow.ToBU_checked_with_defects);
        if(isDefect == true)
        {
            currentProcessFlows.push(ProcessFlow.ToDivide_BU);
        }
        else
        {
            currentProcessFlows.push(ProcessFlow.ToBU_paid);
        }
    }

    function BU_completed(uint _actualCompletionDate)
        public
        OnlyContractor()
        inProcessFlow(ProcessFlow.ToBU_completed)
    {
        actualCompletionDate = _actualCompletionDate;
        deleteFlow(ProcessFlow.ToBU_completed);
        currentProcessFlows.push(ProcessFlow.ToBU_checked_with_defects);
    }

    function BU_paid()
        public
        payable
        OnlyClient()
        inProcessFlow(ProcessFlow.ToBU_paid)
        returns (uint _plannedPaymentAmount)
    {
        Client.transfer(plannedPaymentAmount);
        _plannedPaymentAmount = 14;
        deleteFlow(ProcessFlow.ToBU_paid);
    }

    function BU_started(uint _actualStartDate)
        public
        OnlyContractor()
        inProcessFlow(ProcessFlow.ToBU_started)
    {
        actualStartDate = _actualStartDate;
        deleteFlow(ProcessFlow.ToBU_started);
        currentProcessFlows.push(ProcessFlow.ToBU_completed);
    }

    function Divide_BU()
        public
        OnlyClient()
        inProcessFlow(ProcessFlow.ToDivide_BU)
    {
        deleteFlow(ProcessFlow.ToDivide_BU);
        currentProcessFlows.push(ProcessFlow.ToBU_C_paid);
        currentProcessFlows.push(ProcessFlow.ToBU_D_defined);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract SCProcessFlow{

//Automated generated process state based on process flows
    enum ProcessFlow { ToBU_started, ToBU_completed, ToBU_checked_with_defects, ToBU_paid, ToDivide_BU, ToBU_C_paid, ToBU_D_defined, ToBU_D_checked }

    ProcessFlow[] currentProcessFlows;

    modifier inProcessFlow(ProcessFlow _processFlow){
        for(uint i=0; i<currentProcessFlows.length; i++)
        {
           if(currentProcessFlows[i] == _processFlow)
           {
             _;
             return;
           }
        }
        revert("Invalid state of the process flow. Please check by getCurrentProcessState().");
    }

    constructor()
    {
        currentProcessFlows.push(ProcessFlow.ToBU_started);
    }

    function getCurrentProcessState()
        public
        view
        returns(ProcessFlow[] memory)
    {
        return currentProcessFlows;
    }

    function deleteFlow(ProcessFlow _processFlow)
        internal
    {
        for(uint i=0; i<currentProcessFlows.length; i++)
        {
            if(currentProcessFlows[i] == _processFlow)
            {
                currentProcessFlows[i] = currentProcessFlows[currentProcessFlows.length-1];
                currentProcessFlows.pop();
            }
        }
    }

}