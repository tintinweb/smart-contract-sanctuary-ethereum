// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

contract SmartLeaseRegistry {
    event LeaseContractCreated(
        uint256 timestamp,
        address newLeaseContractAddress,
        address landlord,
        uint8 capacity
    );
    address[] contracts;

    function createLease(uint8 _capacity) public {
        address newLeaseContract = address(
            new SmartLeaseContract(payable(msg.sender), _capacity)
        );
        contracts.push(newLeaseContract);

        emit LeaseContractCreated(
            block.timestamp,
            newLeaseContract,
            msg.sender,
            _capacity
        );
    }

    function getLeases() external view returns (address[] memory) {
        return contracts;
    }

    function getNumLeases() external view returns (uint256) {
        return contracts.length;
    }
}

contract SmartLeaseContract {
    event WrittenContractProposed(uint256 timestamp, string ipfsHash);
    event TenantAssigned(
        uint256 timestamp,
        address tenantAddress,
        uint256 rentAmount,
        uint256 depositAmount
    );
    event TenantSigned(uint256 timestamp, address tenantAddress);
    event DepositPayed(
        uint256 timestamp,
        address tenantAddress,
        uint256 amount
    );

    struct Tenant {
        uint256 rentAmount;
        uint256 depositAmount;
        bool hasSigned;
        bool hasPaidDeposit;
        bool initialized;
    }

    mapping(address => Tenant) public addressToTenant;
    Tenant[] public tenants;

    address payable public landlordAddress;
    string public writtenContractIpfsHash;

    uint8 public tenantOccupancy = 0;

    uint256 deposit;
    uint8 public TENANT_CAPACITY;

    // inheritance would be an issue with external constructors
    constructor(address payable _landlordAddress, uint8 _capacity) {
        require(
            _landlordAddress != address(0),
            "Landlord address must not be zero!"
        );
        landlordAddress = _landlordAddress;

        TENANT_CAPACITY = _capacity;
    }

    modifier onlyTenant() {
        require(
            addressToTenant[msg.sender].initialized == true,
            "Only a tenant can invoke this functionality"
        );
        _;
    }

    modifier onlyLandlord() {
        require(
            msg.sender == landlordAddress,
            "Only the landlord can invoke this functionality"
        );
        _;
    }

    modifier isContractProposed() {
        require(
            !(isSameString(writtenContractIpfsHash, "")),
            "The written contract has not been proposed yet"
        );
        _;
    }

    modifier hasSigned() {
        require(
            addressToTenant[msg.sender].hasSigned == true,
            "Tenant must sign the contract before invoking this functionality"
        );
        _;
    }

    modifier notZeroAddres(address addr) {
        require(addr != address(0), "0th address is not allowed!");
        _;
    }

    function proposeWrittenContract(string calldata _writtenContractIpfsHash)
        external
        onlyLandlord
    {
        // Update written contract ipfs hash
        writtenContractIpfsHash = _writtenContractIpfsHash;
        emit WrittenContractProposed(block.timestamp, _writtenContractIpfsHash);
    }

    function assignTenant(
        address _tenantAddress,
        uint256 _rentAmount,
        uint256 _depositAmount
    ) external onlyLandlord isContractProposed notZeroAddres(_tenantAddress) {
        // require room in the house
        require(
            tenantOccupancy < TENANT_CAPACITY,
            "The rental unit is fully occupied."
        );
        require(
            _tenantAddress != landlordAddress,
            "Landlord is not allowed to be a tenant at the same time."
        );
        require(
            addressToTenant[_tenantAddress].initialized == false,
            "Duplicate tenants are not allowed."
        );

        tenants.push(Tenant(_rentAmount, _depositAmount, false, false, true));
        addressToTenant[_tenantAddress] = tenants[tenantOccupancy];
        tenantOccupancy++;

        emit TenantAssigned(
            block.timestamp,
            _tenantAddress,
            _rentAmount,
            _depositAmount
        );
    }

    function signContract() external onlyTenant isContractProposed {
        require(
            addressToTenant[msg.sender].hasSigned == false,
            "The tenant has already signed the contract"
        );

        // Tenant signed
        addressToTenant[msg.sender].hasSigned = true;

        emit TenantSigned(block.timestamp, msg.sender);
    }

    function payDeposit() external payable onlyTenant hasSigned {
        require(
            msg.value == addressToTenant[msg.sender].depositAmount,
            "Amount of provided deposit does not match the amount of required deposit"
        );

        require(
            addressToTenant[msg.sender].hasPaidDeposit == false,
            "The tenant has already paid the deposit"
        );

        deposit += msg.value;
        addressToTenant[msg.sender].hasPaidDeposit = true;

        emit DepositPayed(block.timestamp, msg.sender, msg.value);
    }

    function isSameString(string memory string1, string memory string2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(string1)) ==
            keccak256(abi.encodePacked(string2));
    }
}