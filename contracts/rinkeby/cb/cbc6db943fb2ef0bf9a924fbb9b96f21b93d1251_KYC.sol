// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

/** 
Assumptions
* Finanicial Institutions - Bank
* Users - Customer
* Super Admin - Admin
*/

import "./Customers.sol";
import "./Banks.sol";

/**
 * @title KYC
 * @dev Library for managing KYC process seemlessly using de-centralised system
 */
contract KYC is Customers, Banks {
    address admin;
    address[] internal userList;

    mapping(address => Types.User) internal users;
    mapping(string => Types.KycRequest) internal kycRequests;
    mapping(address => address[]) internal bankCustomers; // All customers associated to a Bank
    mapping(address => address[]) internal customerbanks; // All banks associated to a Customer

    /**
     * @notice Set admin to one who deploy this contract
     * Who will act as the super-admin to add all the financial institutions (banks)
     * @param name_ Name of the admin
     * @param email_ Email of the admin
     */
    constructor(string memory name_, string memory email_) {
        admin = msg.sender;
        Types.User memory usr_ = Types.User({
            name: name_,
            email: email_,
            id_: admin,
            role: Types.Role.Admin,
            status: Types.BankStatus.Active
        });
        users[admin] = usr_;
        userList.push(admin);
    }

    // Modifiers

    /**
     * @notice Checks whether the requestor is admin
     */
    modifier isAdmin() {
        require(msg.sender == admin, "Only admin is allowed");
        _;
    }

    // Support functions

    /**
     * @notice Checks whether the KYC request already exists
     * @param reqId_ Unique Id of the KYC request
     * @return boolean which says request exists or not
     */
    function kycRequestExists(string memory reqId_)
        internal
        view
        returns (bool)
    {
        require(!Helpers.compareStrings(reqId_, ""), "Request Id empty");
        return Helpers.compareStrings(kycRequests[reqId_].id_, reqId_);
    }

    /**
     * @notice All kyc requests. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @param isForBank List needed for bank or for customer
     * @return totalPages Total pages available
     * @return KycRequest[] List of KYC requests in the current page
     */
    function getKYCRequests(uint256 pageNumber, bool isForBank)
        internal
        view
        returns (uint256 totalPages, Types.KycRequest[] memory)
    {
        require(pageNumber > 0, "PN should be > zero");
        (
            uint256 pages,
            uint256 pageLength_,
            uint256 startIndex_,
            uint256 endIndex_
        ) = Helpers.getIndexes(
                pageNumber,
                isForBank
                    ? bankCustomers[msg.sender]
                    : customerbanks[msg.sender]
            );
        Types.KycRequest[] memory list_ = new Types.KycRequest[](pageLength_);
        for (uint256 i = startIndex_; i < endIndex_; i++)
            list_[i] = isForBank
                ? kycRequests[
                    Helpers.append(msg.sender, bankCustomers[msg.sender][i])
                ]
                : kycRequests[
                    Helpers.append(customerbanks[msg.sender][i], msg.sender)
                ];
        return (pages, list_);
    }

    // Events

    event KycRequestAdded(string reqId, string bankName, string customerName);
    event KycReRequested(string reqId, string bankName, string customerName);
    event KycStatusChanged(
        string reqId,
        address customerId,
        address bankId,
        Types.KycStatus status
    );
    event DataHashPermissionChanged(
        string reqId,
        address customerId,
        address bankId,
        Types.DataHashStatus status
    );

    // Admin Interface

    /**
     * @dev All the banks list. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @return totalPages Total pages available
     * @return Bank[] List of banks in the current page
     */
    function getAllBanks(uint256 pageNumber)
        public
        view
        isAdmin
        returns (uint256 totalPages, Types.Bank[] memory)
    {
        return getallbanks(pageNumber);
    }

    /**
     * @dev To add new bank account
     * @param bank_ Bank details, which need to be added to the system
     */
    function addBank(Types.Bank memory bank_) public isAdmin {
        addbank(bank_);
        // Adding to common list
        users[bank_.id_] = Types.User({
            name: bank_.name,
            email: bank_.email,
            id_: bank_.id_,
            role: Types.Role.Bank,
            status: Types.BankStatus.Active
        });
        userList.push(bank_.id_);
    }

    /**
     * @dev To add new bank account
     * @param id_ Bank's metamask address
     * @param email_ Bank's email address that need to be updated
     * @param name_ Bank's name which need to be updated
     */
    function updateBankDetails(
        address id_,
        string memory email_,
        string memory name_
    ) public isAdmin {
        updatebank(id_, email_, name_);
        // Updating in common list
        users[id_].name = name_;
        users[id_].email = email_;
    }

    /**
     * @dev To add new bank account
     * @param id_ Bank's metamask address
     * @param makeActive_ If true, bank will be marked as active, else, it will be marked as deactivateds
     */
    function activateDeactivateBank(address id_, bool makeActive_)
        public
        isAdmin
    {
        // Updating in common list
        users[id_].status = activatedeactivatebank(id_, makeActive_);
    }

    // Bank Interface

    /**
     * @dev List of customers, who are linked to the current bank. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @return totalPages Total pages available
     * @return KycRequest[] List of KYC requests in the current page
     */
    function getCustomersOfBank(uint256 pageNumber)
        public
        view
        isValidBank(msg.sender)
        returns (uint256 totalPages, Types.KycRequest[] memory)
    {
        return getKYCRequests(pageNumber, true);
    }

    /**
     * @notice Records new KYC request for a customer
     * @param customer_ Customer details for whom the request is to be raised
     * @param currentTime_ Current Date & Time in unix epoch timestamp
     * @param notes_ Any additional notes that need to be added
     */
    function addKycRequest(
        Types.Customer memory customer_,
        uint256 currentTime_,
        string memory notes_
    ) public isValidBank(msg.sender) {
        string memory reqId_ = Helpers.append(msg.sender, customer_.id_);
        require(!kycRequestExists(reqId_), "User had kyc req.");

        kycRequests[reqId_] = Types.KycRequest({
            id_: reqId_,
            userId_: customer_.id_,
            customerName: customer_.name,
            bankId_: msg.sender,
            bankName: getsinglebank(msg.sender).name,
            dataHash: customer_.dataHash,
            updatedOn: currentTime_,
            status: Types.KycStatus.Pending,
            dataRequest: Types.DataHashStatus.Pending,
            additionalNotes: notes_
        });
        bankCustomers[msg.sender].push(customer_.id_);
        customerbanks[customer_.id_].push(msg.sender);
        emit KycRequestAdded(
            reqId_,
            kycRequests[reqId_].bankName,
            customer_.name
        );

        if (!customerExists(customer_.id_)) {
            addcustomer(customer_);
            // Adding to common list
            users[customer_.id_] = Types.User({
                name: customer_.name,
                email: customer_.email,
                id_: customer_.id_,
                role: Types.Role.Customer,
                status: Types.BankStatus.Active
            });
            userList.push(customer_.id_);
        }
    }

    /**
     * @notice Updates existing KYC request for a customer (It's a re-request)
     * @param id_ Customer ID for whom the request has to be re-raised
     * @param notes_ Any additional notes that need to be added
     */
    function reRequestForKycRequest(address id_, string memory notes_)
        public
        isValidBank(msg.sender)
    {
        string memory reqId_ = Helpers.append(msg.sender, id_);
        require(kycRequestExists(reqId_), "KYC req not found");
        require(customerExists(id_), "User not found");

        // kycRequests[reqId_].status = Types.KycStatus.Pending;
        kycRequests[reqId_].dataRequest = Types.DataHashStatus.Pending;
        kycRequests[reqId_].additionalNotes = notes_;

        emit KycReRequested(
            reqId_,
            kycRequests[reqId_].bankName,
            kycRequests[reqId_].customerName
        );
    }

    /**
     * @dev To mark the KYC verification as failure
     * @param userId_ Id of the user
     * @param userId_ KYC Verified
     * @param note_ Any info that need to be shared
     */
    function updateKycVerification(
        address userId_,
        bool verified_,
        string memory note_
    ) public isValidBank(msg.sender) {
        string memory reqId_ = Helpers.append(msg.sender, userId_);
        require(kycRequestExists(reqId_), "User doesn't have KYC req");

        Types.KycStatus status_ = Types.KycStatus.Pending;
        if (verified_) {
            status_ = Types.KycStatus.KYCVerified;
            updatekyccount(msg.sender);
            updatekycdoneby(userId_);
        } else {
            status_ = Types.KycStatus.KYCFailed;
        }

        kycRequests[reqId_].status = status_;
        kycRequests[reqId_].additionalNotes = note_;
        emit KycStatusChanged(reqId_, userId_, msg.sender, status_);
    }

    /**
     * @dev Search for customer details in the list that the bank is directly linked to
     * @param id_ Customer's metamask Id
     * @return boolean to say if customer exists or not
     * @return Customer object to get the complete details of the customer
     * @return KycRequest object to get the details about the request & it's status
     * Costly operation if we had more customers linked to this single bank
     */
    function searchCustomers(address id_)
        public
        view
        isValidCustomer(id_)
        isValidBank(msg.sender)
        returns (
            bool,
            Types.Customer memory,
            Types.KycRequest memory
        )
    {
        bool found_;
        Types.Customer memory customer_;
        Types.KycRequest memory request_;
        (found_, customer_) = searchcustomers(id_, bankCustomers[msg.sender]);
        if (found_) request_ = kycRequests[Helpers.append(msg.sender, id_)];
        return (found_, customer_, request_);
    }

    // Customer Interface

    /**
     * @notice List of all banks. Data will be sent in pages to avoid the more gas fee
     * @dev This is customer facing RPC end point
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @return totalPages Total pages available
     * @return KycRequest[] List of KYC requests in the current page
     */
    function getBankRequests(uint256 pageNumber)
        public
        view
        isValidCustomer(msg.sender)
        returns (uint256 totalPages, Types.KycRequest[] memory)
    {
        return getKYCRequests(pageNumber, false);
    }

    /**
     * @dev Updates the KYC request (Either Approves or Rejects)
     * @param bankId_ Id of the bank
     * @param approve_ Approve the data hash or reject
     * @param note_ Any info that need to be shared
     */
    function actionOnKycRequest(
        address bankId_,
        bool approve_,
        string memory note_
    ) public isValidCustomer(msg.sender) isValidBank(bankId_) {
        string memory reqId_ = Helpers.append(bankId_, msg.sender);
        require(kycRequestExists(reqId_), "User doesn't have KYC req");

        Types.DataHashStatus status_ = Types.DataHashStatus.Pending;
        if (approve_) {
            status_ = Types.DataHashStatus.Approved;
        } else {
            status_ = Types.DataHashStatus.Rejected;
        }
        kycRequests[reqId_].dataRequest = status_;
        kycRequests[reqId_].additionalNotes = note_;

        emit DataHashPermissionChanged(reqId_, msg.sender, bankId_, status_);
    }

    /**
     * @dev Updates the user profile
     * @param name_ Customer name
     * @param email_ Email that need to be updated
     * @param mobile_ Mobile number that need to be updated
     */
    function updateProfile(
        string memory name_,
        string memory email_,
        uint256 mobile_
    ) public isValidCustomer(msg.sender) {
        updateprofile(name_, email_, mobile_);
        // Updating in common list
        users[msg.sender].name = name_;
        users[msg.sender].email = email_;
    }

    /**
     * @dev Updates the Datahash of the documents
     * @param hash_ Data hash value that need to be updated
     * @param currentTime_ Current Date Time in unix epoch timestamp
     */
    function updateDatahash(string memory hash_, uint256 currentTime_)
        public
        isValidCustomer(msg.sender)
    {
        updatedatahash(hash_, currentTime_);

        // Reset KYC verification status for all banks
        address[] memory banksList_ = customerbanks[msg.sender];
        for (uint256 i = 0; i < banksList_.length; i++) {
            string memory reqId_ = Helpers.append(banksList_[i], msg.sender);
            if (kycRequestExists(reqId_)) {
                kycRequests[reqId_].dataHash = hash_;
                kycRequests[reqId_].updatedOn = currentTime_;
                kycRequests[reqId_].status = Types.KycStatus.Pending;
                kycRequests[reqId_].additionalNotes = "Updated all my docs";
            }
        }
    }

    /**
     * @dev Removes the permission to a specific bank, so that they can't access the documents again
     * @param bankId_ Id of the bank to whom permission has to be revoked
     * @param notes_ Any additional notes that need to included
     */
    function removerDatahashPermission(address bankId_, string memory notes_)
        public
        isValidCustomer(msg.sender)
    {
        string memory reqId_ = Helpers.append(bankId_, msg.sender);
        require(kycRequestExists(reqId_), "Permission not found");
        kycRequests[reqId_].dataRequest = Types.DataHashStatus.Rejected;
        kycRequests[reqId_].additionalNotes = notes_;
        emit DataHashPermissionChanged(
            reqId_,
            msg.sender,
            bankId_,
            Types.DataHashStatus.Rejected
        );
    }

    /**
     * @dev Search for bank details in the list that the customer is directly linked to
     * @param bankId_ Bank's metamask Id
     * @return boolean to say if bank exists or not
     * @return Bank object to get the complete details of the bank
     * @return KycRequest object to get the details about the request & it's status
     * Costly operation if we had more banks linked to this single customer
     */
    function searchBanks(address bankId_)
        public
        view
        isValidCustomer(msg.sender)
        isValidBank(bankId_)
        returns (
            bool,
            Types.Bank memory,
            Types.KycRequest memory
        )
    {
        bool found_;
        Types.Bank memory bank_;
        Types.KycRequest memory request_;
        address[] memory banks_ = customerbanks[msg.sender];

        for (uint256 i = 0; i < banks_.length; i++) {
            if (banks_[i] == bankId_) {
                found_ = true;
                bank_ = getsinglebank(bankId_);
                request_ = kycRequests[Helpers.append(bankId_, msg.sender)];
                break;
            }
        }
        return (found_, bank_, request_);
    }

    // Common Interface

    /**
     * @dev Updates the KYC request (Either Approves or Rejects)
     * @return User object which contains the role & other basic info
     */
    function whoAmI() public view returns (Types.User memory) {
        require(msg.sender != address(0), "Sender Id Empty");
        require(users[msg.sender].id_ != address(0), "User Id Empty");
        return users[msg.sender];
    }

    /**
     * @dev To get details of the customer
     * @param id_ Customer's metamask address
     * @return Customer object which will have complete details of the customer
     */
    function getCustomerDetails(address id_)
        public
        view
        isValidCustomer(id_)
        returns (Types.Customer memory)
    {
        return getcustomerdetails(id_);
    }

    /**
     * @dev To get details of the bank
     * @param id_ Bank's metamask address
     * @return Bank object which will have complete details of the bank
     */
    function getBankDetails(address id_)
        public
        view
        isValidBank(id_)
        returns (Types.Bank memory)
    {
        return getsinglebank(id_);
    }
}