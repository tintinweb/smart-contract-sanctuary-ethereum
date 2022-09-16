/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library SafeMath {
    function safeAdd(uint256 a, uint256 b) external pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) external pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) external pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) external pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {
    function totalSupply() external returns (uint256);

    function balanceOf(address tokenOwner) external returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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

contract MainContract is ReentrancyGuard {
    using SafeMath for uint256;
    address payable platform_owner =
        payable(0x259948d76C34636ED099529Ea977Db1769B7D545);
    struct AccountData {
        uint8 accountType; // 0 => Freelancer, 1 => Customer
        address personWalletAddress;
        uint256 personWorkCount;
        uint256[] personPuan; // Rate x/5
        address[] WorkAddresses; // All work addresses
        string personInfoData;
    }

    mapping(address => AccountData) accounts;
    mapping(address => bool) personsAddress;
    mapping(address => uint256) public feeRates;
    mapping(address => bool) public isDeployedWorks;
    uint256 public bnbFeeRate;
    address[] public deployedWorks;
    address[] public allPersons;
    address payable public feeAddress;
    bool public isActive = true;

    modifier isInAccounts() {
        require(personsAddress[msg.sender]);
        _;
    }
    modifier onlyOwner() {
        require(platform_owner == payable(msg.sender));
        _;
    }
    modifier mustActive() {
        require(isActive);
        _;
    }

    constructor(uint256 _bnbFeeRate, address payable _feeAddress) {
        bnbFeeRate = _bnbFeeRate;
        feeAddress = _feeAddress;
    }

    function changeActive(bool _active) external {
        isActive = _active;
    }

    function changeAvailableTokenFee(address _tokenAddress, uint256 _feeRate)
        external
        onlyOwner
    {
        feeRates[_tokenAddress] = _feeRate;
    }

    function changeSettings(uint256 _bnbFeeRate, address payable _feeAddress)
        external
        onlyOwner
    {
        bnbFeeRate = _bnbFeeRate;
        feeAddress = _feeAddress;
    }
    function getAllPersons() external view returns (address[] memory) {
        return allPersons;
    }

    function addPerson(uint8 _accountType, string memory _personInfoData)
        external
        mustActive
        nonReentrant
    {
        AccountData memory newAccount = AccountData({
            accountType: _accountType,
            personWalletAddress: msg.sender,
            personWorkCount: 0,
            personPuan: new uint256[](0),
            WorkAddresses: new address[](0),
            personInfoData: _personInfoData
        });

        accounts[msg.sender] = newAccount; // Adding a new account
        allPersons.push(msg.sender); // Adding a new account
        personsAddress[msg.sender] = true;
    }

    function getPersonInfoData(address _personAddress)
        external
        view
        returns (
            uint8,
            uint256,
            uint256[] memory,
            address[] memory,
            string memory
        )
    {
        AccountData storage data = accounts[_personAddress];
        return (
            data.accountType,
            data.personWorkCount,
            data.personPuan,
            data.WorkAddresses,
            data.personInfoData
        );
    }

    function getPersonAccountType(address _personAddress)
        public
        view
        returns (uint8)
    {
        AccountData storage data = accounts[_personAddress];
        return data.accountType;
    }

    function updatePerson(string memory _personInfoData)
        external
        isInAccounts
        mustActive
    {
        AccountData storage data = accounts[msg.sender];
        data.personInfoData = _personInfoData;
    }

    function createWork(
        string memory _workTitle,
        string memory _workCategory,
        string memory _workDescription,
        string memory _workAvarageBudget
    ) external mustActive {
        AccountData storage data = accounts[msg.sender];
        WorkContract newWork = new WorkContract(
            _workTitle,
            _workCategory,
            _workDescription,
            _workAvarageBudget,
            payable(msg.sender),
            address(this)
        );
        data.WorkAddresses.push(address(newWork)); // Adding Person Works
        deployedWorks.push(address(newWork)); // Adding All Works
        isDeployedWorks[address(newWork)] = true;
    }

    function getWorks() external view returns (address[] memory) {
        return deployedWorks;
    }

    function setPuan(uint256 _puan, address payable _freelancerAddress)
        external
    {
        AccountData storage data = accounts[_freelancerAddress];
        data.personPuan.push(_puan);
    }
    function setFreelancerWorkAddress(
        address _workAddress,
        address payable _freelanceraddress
    ) external {
        require(isDeployedWorks[msg.sender]);
        AccountData storage data = accounts[_freelanceraddress];
        data.WorkAddresses.push(_workAddress);
    }

    function _removeApproverWorkAddressArray(
        uint256 index,
        address _approveraddress
    ) private {
        AccountData storage data = accounts[_approveraddress];

        if (index >= data.WorkAddresses.length) return;

        for (uint256 i = index; i < data.WorkAddresses.length - 1; i++) {
            data.WorkAddresses[i] = data.WorkAddresses[i + 1];
        }
        delete data.WorkAddresses[data.WorkAddresses.length - 1];
        data.WorkAddresses.length;
    }

    function checkDeadline(address _workAddress)
        external
        view
        returns (bool, address)
    {
        WorkContract deployedWork;
        deployedWork = WorkContract(_workAddress);
        if (
            block.timestamp > deployedWork.deadLine() &&
            deployedWork.deadLine() != 0
        ) {
            return (true, _workAddress);
        } else {
            return (false, _workAddress);
        }
    }
}

contract WorkContract is ReentrancyGuard {
    using SafeMath for uint256;
        uint256 deadline;
        bool tokenContractIsBNB;
        bool BratsShield;
        uint256 offerPrice;

    MainContract deployedFromContract;
    struct Offer {
        uint256 offerPrice;
        address payable freelancerAddress;
        string description;
        string title;
        uint256 deadline;
        bool tokenContractIsBNB;
        bool BratsShield;
    }

    string public workTitle;
    string public workCategory;
    string public workDescription;
    string public workAvarageBudget;
    string public workFilesLink;
    string public employerCancelDescription;
    string public approverReport;
    string public employerRemark;

    uint256 public workCreateTime;
    uint256 public deadLine;
    uint256 public freelancerSendFilesDate;
    uint256 public workStartDate;
    uint256 public workEndDate;
    uint256 public workPrice;
    uint256 public workOfferCount;

    bool public workStatus;
    bool public isBNB;
    bool public bratsShield;
    bool public freelancerSendFiles;
    bool public employerReceiveFiles;

    address payable public employerAddress;
    address payable public freelancerAddress;
    address[] public allFreelancerAddress;

    mapping(address => Offer) offers;

    modifier mustActive() {
        require(deployedFromContract.isActive());
        _;
    }

    constructor(
        string memory _workTitle,
        string memory _workCategory,
        string memory _workDescription,
        string memory _workAvarageBudget,
        address payable _employerAddress,
        address _t
    ) {
        workTitle = _workTitle;
        workCategory = _workCategory;
        workDescription = _workDescription;
        workCreateTime = block.timestamp;
        workAvarageBudget = _workAvarageBudget;
        workOfferCount = 0;
        workStatus = true;
        employerAddress = _employerAddress;
        freelancerSendFiles = false;
        employerReceiveFiles = false;
        deployedFromContract = MainContract(_t);
    }

    function getWorkData()
        external
        view
        returns (
            string memory,
            string memory,
            uint256,
            string memory,
            uint256,
            bool
        )
    {
        return (
            workTitle,
            workDescription,
            workCreateTime,
            workAvarageBudget,
            workOfferCount,
            workStatus
        );
    }

    function getAllFreelancers() external view returns (address[] memory) {
        return allFreelancerAddress;
    }

    function updateWork(
        string memory _workTitle,
        string memory _workCategory,
        string memory _workDescription,
        string memory _workAvarageBudget,
        address _workaddress
    ) external mustActive {
        require(address(this) == _workaddress);
        workTitle = _workTitle;
        workCategory = _workCategory;
        workDescription = _workDescription;
        workAvarageBudget = _workAvarageBudget;
    }

    function createOffer(
        uint256 _offerPrice,
        string memory _description,
        uint256 _deadline,
        string memory _title,
        bool _isBNB,
        bool _BratsShield
    ) external mustActive {
        Offer memory newOffer = Offer({
            offerPrice: _offerPrice,
            freelancerAddress: payable(msg.sender),
            description: _description,
            deadline: _deadline,
            title: _title,
            tokenContractIsBNB: _isBNB,
            BratsShield: _BratsShield
        });
        offers[msg.sender] = newOffer;
        allFreelancerAddress.push(msg.sender);
        workOfferCount++;
    }

    function deleteOffer() external mustActive {
        delete offers[msg.sender];
        workOfferCount--;
    }

    function updateOffer(
        uint256 _offerPrice,
        string memory _description,
        string memory _title,
        bool _BratsShield
    ) external mustActive {
        Offer storage data = offers[msg.sender];
        data.offerPrice = _offerPrice;
        data.description = _description;
        data.title = _title;
        data.BratsShield = _BratsShield;
    }

    function getOfferData(address payable _freelancerAddress)
        external
        view
        returns (
            uint256,
            address,
            string memory,
            string memory,
            uint256,
            bool,
            bool
        )
    {
        Offer storage data = offers[_freelancerAddress];
        return (
            data.offerPrice,
            data.freelancerAddress,
            data.description,
            data.title,
            data.deadline,
            data.tokenContractIsBNB,
            data.BratsShield
        );
    }

    function selectOffer(
        address payable _freelancerAddress
    ) external payable mustActive {
        freelancerAddress = _freelancerAddress;
        workStatus = true;
        workStartDate = block.timestamp;
        deadLine = deadline;
        workPrice = offerPrice;
        isBNB = true;
        bratsShield = BratsShield;
    }
    function freelancerSendFile(string memory _workFilesLink) external {
        freelancerSendFiles = true;
        workFilesLink = _workFilesLink;
        freelancerSendFilesDate = block.timestamp;
    }

    function _payFreelancer() private {
        uint256 amount;

        if (isBNB) {
            amount = workPrice.safeSub(
                (workPrice.safeMul(deployedFromContract.bnbFeeRate())).safeDiv(
                    1e6
                )
            );
            freelancerAddress.transfer(amount);
            deployedFromContract.feeAddress().transfer(
                workPrice.safeSub(amount)
            );
        }
    }

    function _payEmployer() private {
        if (isBNB) {
            employerAddress.transfer(workPrice);
        }
    }

    function employerReceiveFile(uint256 _puan, string memory _remark)
        external
        nonReentrant
    {
        _payFreelancer();
        deployedFromContract.setPuan(_puan, freelancerAddress);
        employerRemark = _remark;
        employerReceiveFiles = true;
        workEndDate = block.timestamp;
    }

    function employerCancel(string memory _depscription) external {
        employerCancelDescription = _depscription;
    }

    function confirmApprover(string memory _description) external nonReentrant {
        if (block.timestamp > block.timestamp + 84600) {}
        _payFreelancer();
        approverReport = _description;
        workEndDate = block.timestamp;
    }

    function cancelApprover(string memory _description) external nonReentrant {
        if (block.timestamp > block.timestamp + 84600) {}
        approverReport = _description;
        _payEmployer();
    }

    function autoConfirm() external nonReentrant {
        require(block.timestamp > freelancerSendFilesDate.safeAdd(1 days));
        require(!employerReceiveFiles);
        require(freelancerSendFiles);
        _payFreelancer();
        deployedFromContract.setPuan(5, freelancerAddress);
        employerRemark = "Auto Confirmed By Smart Contract";
        workEndDate = block.timestamp;
    }

    function sendDeadline() external nonReentrant {
        require(block.timestamp > deadLine);
        require(!freelancerSendFiles);
        _payEmployer();
    }
}