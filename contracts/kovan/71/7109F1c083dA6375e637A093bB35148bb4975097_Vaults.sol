/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// File: contracts/Vaults.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Vaults {
    //global scope variables//

    string public name = "Proton Vaults";

    struct Trust {
        address grantor;
        address beneficiary;
        string  name;
        bool    release_periodic;
        uint    release_on_unix;
        uint    period_days;
        uint    period_amount;
        uint    balance;
        uint    id;
        uint    claimed_amount;
    }

    Trust[] private trusts;

    mapping (uint => address) private grantorOf;
    mapping (uint => address) private beneficOf;
    mapping (address => uint) private countAsGrantor;
    mapping (address => uint) private countAsBenefic;

    //modifiers//

    modifier onlyGrantorOf(uint _id) {
        require(isGrantorOf(_id), "Authorization failed: Only the grantor can perform this action");
        _;
    }

    modifier onlyBeneficOf(uint _id) {
        require(isBeneficOf(_id), "Authorization failed: Only beneficiary can perform this action");
        _;
    }

    //authorizations// (read-only)

    function isGrantorOf(uint _id) public view returns(bool) {
        return msg.sender == grantorOf[_id];
    }

    function isBeneficOf(uint _id) public view returns(bool) {
        return msg.sender == beneficOf[_id];
    }

    //read-write functions//

    function createTrust(
        address         _beneficiary,
        string calldata _name,
        bool            _release_periodic,
        uint            _release_on_unix,
        uint            _period_days,
        uint            _period_amount
        )
        external payable {
        
        //req period amount is <= balance
        require(_period_amount <= msg.value, "Invalid calldata: Amount per period cannot exceed balance");

        //mapping grantor and beneficiary to trust id
        uint id       = trusts.length;
        grantorOf[id] = msg.sender;
        beneficOf[id] = _beneficiary;

        //create new Trust and push to trusts array
        trusts.push(Trust(
            msg.sender,
            _beneficiary,
            _name,
            _release_periodic,
            _release_on_unix,
            _period_days,
            _period_amount,
            msg.value,
            id,
            0
        ));

        //increment trusts count of grantor and beneficiary
        countAsGrantor[msg.sender]++;
        countAsBenefic[_beneficiary]++;
    }

    function modifyTrust(
        string calldata _name,
        bool            _release_periodic,
        uint            _release_on_unix,
        uint            _period_days,
        uint            _period_amount,
        uint            _id
        ) 
        external onlyGrantorOf(_id) {

        //ref to Trust{} in storage
        Trust storage ref = trusts[_id];

        //req period amount is <= balance
        require(_period_amount <= ref.balance, "Invalid calldata: Amount per period cannot exceed balance");

        //overwrite these values with new
        ref.name             = _name;
        ref.release_periodic = _release_periodic;
        ref.release_on_unix  = _release_on_unix;
        ref.period_days      = _period_days;
        ref.period_amount    = _period_amount;
    }

    function transferOwnership(uint _id, address _newOwner) external onlyGrantorOf(_id) {
        //ref to Trust{} in storage
        Trust storage ref = trusts[_id];

        //overwrite .grantor
        ref.grantor = _newOwner;

        //overwrite id mapping to grantor
        grantorOf[_id] = _newOwner;

        //update count at sender
        countAsGrantor[msg.sender]--;

        //update count at receiver
        countAsGrantor[_newOwner]++;
    }

    function increaseBalance(uint _id) external payable onlyGrantorOf(_id) {
        //ref to Trust{} in storage
        Trust storage ref = trusts[_id];

        //add to .balance
        ref.balance += msg.value;
    }

    function decreaseBalance(uint _id, uint _amount) external onlyGrantorOf(_id) {
        //ref to Trust{} in storage
        Trust storage ref = trusts[_id];

        //security redundancy
        require(ref.grantor == msg.sender, "[REDUNDANCY LAYER 1]: Authorization failed: msg.sender is not the authorized grantor of this trust");

        //ensure sufficient balance for withdrwal
        require(ref.balance >= _amount);

        //decrease balance in Trust{} ref
        ref.balance -= _amount;

        //the expected recipient
        address payable recipient = payable(ref.grantor);

        //transfer eth to recipient
        recipient.transfer(_amount);
    }

    function claim(uint _id) external onlyBeneficOf(_id) {
        //ref to Trust{} in storage
        Trust storage ref = trusts[_id];

        //security redundancy
        require(ref.beneficiary == msg.sender, "[REDUNDANCY LAYER 1]: Authorization failed: msg.sender is not the authorized beneficiary of this trust");

        //check release unix is <= now
        require(isClaimable(_id), "Cannot execute claim(): trust at given index is non-claimable");

        //get claim amount
        uint claimAmount = myClaimAmount(_id);

        //ensure sufficient balance for withdrwal
        require(ref.balance >= claimAmount, "Cannot excute claim(): insufficient balance");

        //decrease balance in Trust{} ref
        ref.balance -= claimAmount;

        //update claimed amount in ref
        ref.claimed_amount += claimAmount;

        //the expected recipient
        address payable recipient = payable(ref.beneficiary);

        //transfer eth to recipient
        recipient.transfer(claimAmount);
    }

    //read-only functions// (view)

    function myTrustsAsGrantor() external view returns(Trust[] memory) {
        Trust[] memory result = new Trust[](countAsGrantor[msg.sender]);

        uint index  = 0;
        for (uint i = 0; i < trusts.length; i++) {
            if(trusts[i].grantor == msg.sender) {
                result[index] = trusts[i];
                index++;
            }
        }
        return result; 
    }

    function myTrustsAsBenefic() external view returns(Trust[] memory) {
        Trust[] memory result = new Trust[](countAsBenefic[msg.sender]);

        uint index  = 0;
        for (uint i = 0; i < trusts.length; i++) {
            if(trusts[i].beneficiary == msg.sender) {
                result[index] = trusts[i];
                index++;
            }
        }
        return result; 
    }

    function myClaimAmount(uint _id) public view onlyBeneficOf(_id) returns(uint) {
        //check release unix is <= now
        require(isClaimable(_id), "Cannot execute myClaim(): trust at given index is non-claimable");

        //
        uint amount = 0;

        //copy of Trust{} in storage
        Trust memory ref = trusts[_id];

        if(isPeriodic(_id)) {
            amount = sumPeriodsPassed(_id);
        }
        else {
            amount = uint(trusts[_id].balance);
        }

        //amount cannot exceed balance
        if(amount > ref.balance) { amount = ref.balance; }

        return amount;
    }

    function isClaimable(uint _id) public view returns(bool) {
        uint releaseUnix = trusts[_id].release_on_unix;
        bool result      = releaseUnix <= block.timestamp;
        return result;
    }

    function isPeriodic(uint _id) internal view returns(bool) {
        bool result = trusts[_id].release_periodic;
        return result;
    }

    function sumPeriodsPassed(uint _id) internal view returns(uint) {
        //calc will fail if run against a non-periodic trust (cannot divide by zero days)
        require(isPeriodic(_id), "Type check failed: trust release type is non-periodic");

        //copy of Trust{} in storage
        Trust memory ref = trusts[_id];

        //get days since release
        uint releaseUnix    = uint(ref.release_on_unix);
        uint differenceUnix = uint(block.timestamp) - releaseUnix;
        uint differenceDays = toDays(differenceUnix);

        //get maximum theoretical claim
        uint periodDays = uint(ref.period_days);
        uint numPeriods = uint(differenceDays / periodDays);
        uint perPeriod  = uint(ref.period_amount);
        uint maxClaim   = uint(numPeriods * perPeriod);

        //subtract previosly claimed amount
        uint result = maxClaim - uint(ref.claimed_amount);

        //return result
        return result;
    }

    //onchain calculation// (pure)

    function toDays(uint _seconds) internal pure returns(uint) {
        uint result = uint(_seconds / 86400);
        return result;
    } 

    //debug functions: remove these in production build? (for privacy)//

    function getTrustAt(uint _id) public view returns(Trust memory) {
        return trusts[_id];
    }

    function getGrantorOf(uint _id) external view returns(address) {
        return grantorOf[_id];
    }

    function getBeneficOf(uint _id) external view returns(address) {
        return beneficOf[_id];
    }

    function getTrusts() external view returns(Trust[] memory) {
        return trusts;
    }
}