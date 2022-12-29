// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error InvalidTenant();
error InvalidManager();
error InvalidOwner();

error InsuficientFunds();
error NoAuthorization();
error RequestOwnerAuthorization();
error RequestTenantAuthorization();
error ContractExpired();
error ContractOccupied();
error NoCandidates();

contract smartRent {
    //Struct that defines the values that our contract will be developed in
    //What can be public?

    struct candidate {
        address account;
        uint256 revenue;
    }

    //Owner of the house
    address private s_owner;

    //Unlockit Address
    address private immutable i_manager;

    // Possible tenants
    candidate[] private s_candidates;
    uint256 private nCandidates;

    uint256 private constant UNLOCKIT_FEE = 1;

    //Tenant, the one who is paying the contract
    address private s_chosenTenant;

    //Contract Balance
    uint256 private s_balance;

    //Rent  Price
    uint256 private s_rentPrice;

    //Duration of the contract
    uint256 private s_numberOfMonths;

    //Number of paid months
    uint256 private s_paidMonths;

    // Address => New Duration => True / False
    mapping(address => mapping(uint256 => bool)) private s_extendAuthorizations;

    /**
     * @dev Owner is only responsible for creating the initial
     * state of the renting contract and choosing the appropriate tenant
     */
    constructor(address manager, uint256 rentPrice, uint256 numberOfMonths) {
        s_owner = msg.sender;
        i_manager = manager;
        s_rentPrice = rentPrice;
        s_numberOfMonths = numberOfMonths;
        s_paidMonths = 0;
    }

    /**
     * @dev Mock function
     */

    function chooseTenant() public {
        if (msg.sender != s_owner) {
            revert InvalidOwner();
        }

        if (nCandidates == 0) {
            revert NoCandidates();
        }

        candidate memory bestTenant = s_candidates[0];

        for (uint i = 1; i < nCandidates; i++) {
            if (s_candidates[i].revenue > bestTenant.revenue) {
                bestTenant = s_candidates[i];
            }
        }

        s_chosenTenant = bestTenant.account;
    }

    function increaseOwnerContractDuration(uint256 increasedDuration) public {
        if (msg.sender != s_owner) {
            revert InvalidOwner();
        }

        s_extendAuthorizations[s_owner][increasedDuration] = true;
    }

    /**
     * @dev Manager Functions
     * This function will be called by the chainLink
     * offchain nodes   in the first day of every month
     */

    function processPayment() public payable {
        if (msg.sender != i_manager) {
            revert InvalidManager();
        }

        if (s_balance < s_rentPrice) {
            revert InsuficientFunds();
        }

        if (s_paidMonths == s_numberOfMonths) {
            revert ContractExpired();
        }

        bool success;

        uint256 ownerPayment = (s_rentPrice * (100 - UNLOCKIT_FEE)) / 100;
        uint256 feePayment = (s_rentPrice * UNLOCKIT_FEE) / 100;

        (success, ) = s_owner.call{value: ownerPayment}('');
        require(success, 'Payment Failed');

        (success, ) = i_manager.call{value: feePayment}('');
        require(success, 'Payment Failed');

        s_paidMonths++;
        s_balance -= s_rentPrice;
    }

    /**
     * @dev Tenant Functions
     */

    function applyForRentContract(
        uint256 revenue /* Argumentos Estilo numeros do IRS, etc */
    ) public {
        s_candidates.push(candidate(msg.sender, revenue));
        nCandidates++;
    }

    /**
     * @dev Funds the contract with a certain amount of eth
     */
    function fund() public payable {
        if (msg.sender != s_chosenTenant) {
            revert InvalidTenant();
        }
        s_balance += msg.value;
    }

    /**
     * @dev Registers that the tenant wants to extend the contract for a
     * specific period of time
     */
    function increaseTenantContractDuration(uint256 increasedDuration) public {
        if (msg.sender != s_chosenTenant) {
            revert InvalidTenant();
        }

        s_extendAuthorizations[s_chosenTenant][increasedDuration] = true;
    }

    /**
     * @dev Function to validate an extension of contract
     */

    function increaseContractDuration(uint256 increasedDuration) public {
        if (msg.sender != i_manager) {
            revert InvalidManager();
        }

        if (!s_extendAuthorizations[s_owner][increasedDuration]) {
            revert RequestOwnerAuthorization();
        }

        if (!s_extendAuthorizations[s_chosenTenant][increasedDuration]) {
            revert RequestTenantAuthorization();
        }

        s_extendAuthorizations[s_owner][increasedDuration] = false;
        s_extendAuthorizations[s_chosenTenant][increasedDuration] = false;

        s_numberOfMonths += increasedDuration;
    }

    /**
     * @dev Getters
     */

    function getManager() public view returns (address) {
        return i_manager;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function getBalance() public view returns (uint256) {
        return s_balance;
    }

    function getRentPrice() public view returns (uint256) {
        return s_rentPrice;
    }

    function getUnlockitFee() public pure returns (uint256) {
        return UNLOCKIT_FEE;
    }
}