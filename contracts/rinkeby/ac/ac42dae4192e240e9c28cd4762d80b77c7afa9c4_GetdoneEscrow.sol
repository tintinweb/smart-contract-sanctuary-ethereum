// contracts/GetdoneEscrow.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./GetdoneApp.sol";

interface IGetdoneBanker {
    function initialize() external;
    function send(address receiver, uint256 amount, address erc20) external;
}

interface IGetdoneDisputation {
    function create(uint256 merchantId, uint256 appId, uint256 contractId, address customer, address sender, uint256 amount)  external returns(address);
}

contract GetdoneEscrow is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, AccessControlEnumerableUpgradeable, GetdoneApp{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Clones for address;

    bytes32 constant public DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    uint256 constant public CONTRACT_STATUS_NEW = 0;
    uint256 constant public CONTRACT_STATUS_PROCESSING = 1;
    uint256 constant public CONTRACT_STATUS_ENDED = 2;
    uint256 constant public CONTRACT_STATUS_WITHDRAWN = 3;

    uint256 constant public MILESTONE_STATUS_NEW = 0;
    uint256 constant public MILESTONE_STATUS_CREATED = 1;
    uint256 constant public MILESTONE_STATUS_APPROVED = 2;
    uint256 constant public MILESTONE_STATUS_DECLINED = 3;
    uint256 constant public MILESTONE_STATUS_PAID = 4;
    uint256 constant public MILESTONE_STATUS_PAID_LESS = 5;
    uint256 constant public MILESTONE_STATUS_REQUEST_PAYLESS = 6;
    uint256 constant public MILESTONE_STATUS_DECLINE_PAYLESS = 7;
    uint256 constant public ONE_HUNDRED_PERCENT = 10000; // 100%
    
    event MilestoneChanged(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, uint256 orderId, address talent, address customer, uint256 price, uint256 contractPay, uint256 fee, address erc20, uint256 status);
    event ContractDeposited(uint256 merchantId, uint256 appId, uint256 contractId, uint256 orderId, address customer, uint256 price, address erc20);
    event ContractReceived(uint256 merchantId, uint256 appId, uint256 contractId, address sender, uint256 price, address erc20);
    event ContractPay(uint256 merchantId, uint256 appId, uint256 contractId, address customer, uint256 price, address erc20);
    event ContractEnded(uint256 merchantId, uint256 appId, uint256 contractId, address sender, uint256 refund, address erc20, bool isEndTalent, bool isEndCustomer);
    event ContractEndingDeclined(uint256 merchantId, uint256 appId, uint256 contractId, address sender, uint256 refund, address erc20, bool isEndTalent, bool isEndCustomer);
    event ContractDisputationSent(uint256 merchantId, uint256 appId, uint256 contractId, uint256 amount, address sender, bool isTalentVoted, bool isCustomerVoted);
    event ContractWithdrawn(uint256 merchantId, uint256 appId, uint256 contractId, address customer, uint256 refund, address erc20);
    event Payout(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, uint256 amount, uint256 fee, address erc20, address receiver);
    event GetdoneBankerUpdated(address wallet);
    event DisputationContractUpdated(address disputation);
    event BankerResponse(bool success, bytes data);

    struct Milestone {
        uint256 milestoneId;
        uint256 orderId;
        uint256 price;
        uint256 payless;
        uint256 paid;
        uint256 refund;
        uint256 status;
    }

    struct ContractInfo {
        uint256 merchantId;
        uint256 appId;
        uint256 contractId;
        address customer;
        address talent;
        address erc20;
        uint256 deposit;
        uint256 refund;
        uint256 status;
        bool isEndTalent;
        bool isEndCustomer;
        bool init;
        bool dispute;
        address banker;
    }

    // merchantId => appId => customer => contractId => milestoneId => Milestone
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => mapping(uint256 => Milestone))))) public milestones;
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => uint256[])))) public milestoneIds;
    
    // merchantId => appId =>  customer => contractId => ContractInfo
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => ContractInfo)))) public contractInfos;

    address public bankerAddress;
    address public disputationAddress;

    function initialize()
        public
        initializer
    {
        __Ownable_init();
        __Pausable_init();
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();

        address sender = _msgSender();
        
        merchants[MERCHANT_ID_GETDONE] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setupRole(getRoleMerchantHash(MERCHANT_ID_GETDONE), sender);
    }

    function getRoleMerchantHash(uint256 merchantId) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("MERCHANT_ROLE_", merchantId));
    }

    function isEnd(uint256 merchantId, uint256 appId, uint256 contractId, address customer)
        internal
        view
        returns (bool)
    {
        return contractInfos[merchantId][appId][customer][contractId].isEndCustomer || contractInfos[merchantId][appId][customer][contractId].isEndTalent;
    }

    function isDisputation(uint256 merchantId, uint256 appId, uint256 contractId, address customer)
        internal
        view
        returns (bool)
    {
        return contractInfos[merchantId][appId][customer][contractId].dispute == true;
    }

    function updateMerchant(uint256 merchantId, address admin)
        public
    {
        require((hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || owner() == _msgSender()), "GetdoneEscrow: caller is not the admin");
        _updateMerchant(merchantId);
        if(admin != address(0)) {
            _setupRole(getRoleMerchantHash(merchantId), admin);
        }
    }

    function updateApp(uint256 merchantId, uint256[] memory appIds, address treasury, uint256 fee)
        public
    {
        require(hasRole(getRoleMerchantHash(merchantId), _msgSender()), "GetdoneEscrow: caller is not the merchant");
        _updateApp(merchantId, appIds, treasury, fee);
    }

    function updateBanker(address wallet)
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || owner() == _msgSender(), "GetdoneEscrow: caller is not the admin");
        require(wallet != address(0), "GetdoneEscrow: address is invalid");

        bankerAddress = wallet;

        emit GetdoneBankerUpdated(wallet);
    }

    function updateDisputation(address disputation)
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || owner() == _msgSender(), "GetdoneEscrow: caller is not the admin");
        require(disputation != address(0), "GetdoneEscrow: address is invalid");

        disputationAddress = disputation;

        emit DisputationContractUpdated(disputation);
    }

    function updateErc20Whitelist(uint256 merchantId, address[] memory erc20s, bool status)
        public
    {
        require(hasRole(getRoleMerchantHash(merchantId), _msgSender()), "GetdoneEscrow: caller is not the merchant");
        _updateErc20Whitelist(merchantId, erc20s, status);
    }

    function pause()
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || owner() == _msgSender(), "GetdoneEscrow: caller is not the admin");
        _pause();
    }

    function unpause()
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || owner() == _msgSender(), "GetdoneEscrow: caller is not the admin");
        _unpause();
    }

    function updateMilestoneBalance(uint256 merchantId, uint256 appId, address customer, uint256 contractId) 
        internal
        returns (uint256)
    {
        uint256 amountRefund;
        ContractInfo memory contractInfo = contractInfos[merchantId][appId][customer][contractId];
        uint256 length = milestoneIds[merchantId][appId][customer][contractId].length;
        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                uint256 milestoneId = milestoneIds[merchantId][appId][customer][contractId][i];
                Milestone storage milestone = milestones[contractInfo.merchantId][contractInfo.appId][contractInfo.customer][contractInfo.contractId][milestoneId];
                uint256 balance = milestone.price - milestone.paid - milestone.refund;
                if (balance > 0) {
                    amountRefund += balance;
                    milestone.refund = milestone.refund + balance;
                }
            }
        }
        return amountRefund;
    }

    function createMilestone(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, address talent, uint256 price, address erc20, uint256 orderId) 
        public
        payable
        whenNotPaused
        nonReentrant
    {
        address _customer = _msgSender();
        require(erc20Whitelist[merchantId][erc20] == true, "GetdoneEscrow: erc20 must be in whitelist");
        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require(isEnd(merchantId, appId, contractId, _customer) == false, "GetdoneEscrow: contract has been ended");
        require(isDisputation(merchantId, appId, contractId, _customer) == false, "GetdoneEscrow: contract has disputation");
        require(price > 0, "GetdoneEscrow: price must be greater than 0");

        Milestone storage milestone = milestones[merchantId][appId][_customer][contractId][milestoneId];
        ContractInfo storage contractInfo = contractInfos[merchantId][appId][_customer][contractId];

        require(talent != address(0) && talent != _customer, "GetdoneEscrow: talent address is invalid");
        if (milestone.milestoneId == milestoneId) {
            require((milestone.status == MILESTONE_STATUS_DECLINED), "GetdoneEscrow: Can not update milestone");
        }

        if (contractInfo.init == true) {
            require(contractInfo.erc20 == erc20, "GetdoneEscrow: Erc20 can not change");
            require(contractInfo.customer == _customer, "GetdoneEscrow: can not change sale if sender has not made one");
        }

        // create banker
        if(contractInfo.banker == address(0)) {
            address _banker = bankerAddress.clone();
            IGetdoneBanker(_banker).initialize();
            contractInfo.banker = _banker;
        }

        uint256 amountPay = contractInfo.init == true && contractInfo.deposit > 0 ? (contractInfo.deposit >= price ? 0 : price - contractInfo.deposit) : price;
        uint256 amountContractPay = contractInfo.init == true && contractInfo.deposit > 0 ? (contractInfo.deposit >= price ? price : contractInfo.deposit) : 0;

        if (amountPay > 0) {
            if (erc20 == address(0)) {
                require(msg.value == amountPay, "GetdoneEscrow: deposit amount is not enough");
                // payable(contractInfo.banker).transfer(msg.value);
                (bool success, bytes memory data) = contractInfo.banker.call{value: msg.value}("");
                emit BankerResponse(success, data);
            } else {
                IERC20Upgradeable(erc20).safeTransferFrom(_customer, contractInfo.banker, amountPay);
            }
        }
        if (contractInfo.init == false) {
            

            contractInfo.merchantId = merchantId;
            contractInfo.appId = appId;
            contractInfo.contractId = contractId;
            contractInfo.customer = _customer;
            contractInfo.talent = talent;
            contractInfo.erc20 = erc20;
            contractInfo.deposit = 0;
            contractInfo.refund = 0;
            contractInfo.isEndTalent = false;
            contractInfo.isEndCustomer = false;
            contractInfo.init = true;
            contractInfo.status = CONTRACT_STATUS_PROCESSING;
            milestoneIds[contractInfo.merchantId][contractInfo.appId][contractInfo.customer][contractInfo.contractId].push(milestoneId);
        } else {
            contractInfo.status = CONTRACT_STATUS_PROCESSING;
            if (milestone.milestoneId == 0) {
                milestoneIds[contractInfo.merchantId][contractInfo.appId][contractInfo.customer][contractInfo.contractId].push(milestoneId);
            }
            if (contractInfo.talent == address(0)) {
                contractInfo.talent = talent;
            }
            if (amountContractPay > 0) {
                contractInfo.deposit = contractInfo.deposit - amountContractPay;
            }
        }
        
        milestone.milestoneId = milestoneId;
        milestone.orderId = orderId;
        milestone.price = price;
        milestone.payless = 0;
        milestone.paid = 0;
        milestone.refund = 0;
        milestone.status = MILESTONE_STATUS_CREATED;

        emit MilestoneChanged(contractInfo.merchantId, contractInfo.appId, contractInfo.contractId, milestone.milestoneId, milestone.orderId, contractInfo.talent, contractInfo.customer, amountPay, amountContractPay, 0, contractInfo.erc20, MILESTONE_STATUS_CREATED);
    }
    
    function approveMilestone(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, address customer, bool isAccept) 
        public
        whenNotPaused
        nonReentrant
    {
        address talent = _msgSender();
        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require(isEnd(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has been ended");
        require(isDisputation(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has disputation");
        

        Milestone storage milestone = milestones[merchantId][appId][customer][contractId][milestoneId];
        ContractInfo storage contractInfo = contractInfos[merchantId][appId][customer][contractId];
        require(milestone.status == MILESTONE_STATUS_CREATED, "GetdoneEscrow: Milestone does not allow to approve");
        require(contractInfo.talent == talent, "GetdoneEscrow: can not change milestone if sender is not a talent");
        
        if (isAccept) {
            milestone.status = MILESTONE_STATUS_APPROVED;
            emit MilestoneChanged(merchantId, contractInfo.appId, contractInfo.contractId, milestone.milestoneId, 0, contractInfo.talent, contractInfo.customer, milestone.price, 0, 0, contractInfo.erc20, MILESTONE_STATUS_APPROVED);
        } else { 
            uint256 balance = milestone.price - milestone.paid - milestone.refund;

            if (balance > 0) {
                milestone.price = milestone.price - balance;
                contractInfo.deposit = contractInfo.deposit + balance;
                emit ContractReceived(merchantId, appId, contractId, talent, balance, contractInfo.erc20);
            }

            milestone.status = MILESTONE_STATUS_DECLINED;

            emit MilestoneChanged(merchantId, contractInfo.appId, contractInfo.contractId, milestone.milestoneId, 0, contractInfo.talent, contractInfo.customer, milestone.price, 0, 0, contractInfo.erc20, MILESTONE_STATUS_DECLINED);
        }
    }

    function requestPayLessMilestone(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, uint256 price) 
        public
        whenNotPaused
        nonReentrant
    {
        address customer = _msgSender();
        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require(isEnd(merchantId, appId, contractId, _msgSender()) == false, "GetdoneEscrow: contract has been ended");
        require(isDisputation(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has disputation");
        
        ContractInfo memory contractInfo = contractInfos[merchantId][appId][customer][contractId];
        Milestone storage milestone = milestones[merchantId][appId][customer][contractId][milestoneId];
        require((milestone.status == MILESTONE_STATUS_APPROVED || milestone.status == MILESTONE_STATUS_DECLINE_PAYLESS), "GetdoneEscrow: Milestone does not allow to pay");
        uint256 balance = milestone.price - milestone.paid - milestone.refund;

        require(contractInfo.customer == customer, "GetdoneEscrow: can not change milestone if sender is not a talent");
        require(price > 0 && balance > price, "GetdoneEscrow: price is invalid");

        milestone.status = MILESTONE_STATUS_REQUEST_PAYLESS;
        milestone.payless = price;
        emit MilestoneChanged(merchantId, appId, contractInfo.contractId, milestone.milestoneId, 0, contractInfo.talent, contractInfo.customer, milestone.payless, 0, 0, contractInfo.erc20, MILESTONE_STATUS_REQUEST_PAYLESS);
    }

    function payMilestone(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, uint256 price) 
        public
        whenNotPaused
        nonReentrant
    {
        address customer = _msgSender();
        uint256 fee = apps[merchantId][appId].fee;

        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require(isEnd(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has been ended");
        require(isDisputation(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has disputation");

        ContractInfo storage contractInfo = contractInfos[merchantId][appId][customer][contractId];
        Milestone storage milestone = milestones[merchantId][appId][customer][contractId][milestoneId];
        require((milestone.status == MILESTONE_STATUS_APPROVED || milestone.status == MILESTONE_STATUS_DECLINE_PAYLESS), "GetdoneEscrow: Milestone does not allow to pay");
        
        uint256 balance = milestone.price - milestone.paid - milestone.refund;

        require(contractInfo.customer == customer, "GetdoneEscrow: can not change sale if sender has not made one");
        require(price > 0 && balance == price, "GetdoneEscrow: price is invalid");

        _payout(merchantId, appId, contractInfo.contractId, milestone.milestoneId, contractInfo.customer, contractInfo.talent, balance, contractInfo.erc20);

        milestone.paid = milestone.paid + balance;
        milestone.status = MILESTONE_STATUS_PAID;
        uint256 feeAmount = balance * fee / ONE_HUNDRED_PERCENT;
        emit MilestoneChanged(merchantId, appId, contractInfo.contractId, milestone.milestoneId, 0, contractInfo.talent, contractInfo.customer, balance, 0, feeAmount, contractInfo.erc20, MILESTONE_STATUS_PAID);
    }

    function approvePayLessMilestone(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, address customer, uint256 price, bool isAccept) 
        public
        whenNotPaused
        nonReentrant
    {
        uint256 fee = apps[merchantId][appId].fee;
        address talent = _msgSender();
        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require(isEnd(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has been ended");
        require(isDisputation(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has disputation");
        
        ContractInfo storage contractInfo = contractInfos[merchantId][appId][customer][contractId];
        Milestone storage milestone = milestones[merchantId][appId][customer][contractId][milestoneId];
        require(milestone.status == MILESTONE_STATUS_REQUEST_PAYLESS, "GetdoneEscrow: Milestone does not allow to pay");
        require(contractInfo.talent == talent, "GetdoneEscrow: can not change milestone if sender is not a talent");

        if (isAccept) {
            uint256 balance = milestone.price - milestone.paid - milestone.refund;
            require(price > 0 && milestone.payless == price, "GetdoneEscrow: price is invalid");

            // pay to talent
            _payout(merchantId, appId, contractId, milestone.milestoneId, contractInfo.customer, contractInfo.talent, milestone.payless, contractInfo.erc20);

            milestone.paid = milestone.paid + milestone.payless;
            milestone.status = MILESTONE_STATUS_PAID_LESS;

            // refund to customer
            uint256 refund = balance - milestone.payless;
            if (refund > 0) {
                milestone.refund = milestone.refund + refund;
                contractInfo.deposit = contractInfo.deposit + refund;
            }
            
            uint256 feeAmount = milestone.payless * fee / ONE_HUNDRED_PERCENT;
            emit MilestoneChanged(merchantId, appId, contractInfo.contractId, milestone.milestoneId, milestone.orderId, contractInfo.talent, contractInfo.customer, milestone.payless, 0, feeAmount, contractInfo.erc20, MILESTONE_STATUS_PAID_LESS);
            if (refund > 0) {
                emit ContractReceived(contractInfo.merchantId, contractInfo.appId, contractInfo.contractId, contractInfo.talent, refund, contractInfo.erc20);
            }
        } else{
            milestone.status = MILESTONE_STATUS_DECLINE_PAYLESS;
            emit MilestoneChanged(merchantId, appId, contractInfo.contractId, milestone.milestoneId, 0, contractInfo.talent, contractInfo.customer, milestone.payless, 0, 0, contractInfo.erc20, MILESTONE_STATUS_DECLINE_PAYLESS);
        }
        
    }

    function endContract(uint256 merchantId, uint256 appId, uint256 contractId, address customer, bool isAccept) 
        public
        whenNotPaused
        nonReentrant
    {
        
        address sender = _msgSender();
        ContractInfo storage contractInfo = contractInfos[merchantId][appId][customer][contractId];

        require((contractInfo.customer == sender || contractInfo.talent == sender ), "GetdoneEscrow: can not change contract if sender has not made one");

        require(isDisputation(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has disputation");
        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require((!contractInfo.isEndCustomer || !contractInfo.isEndTalent), "GetdoneEscrow: contract cannot end");
        
        uint256 length = milestoneIds[merchantId][appId][customer][contractId].length;
        bool allow = true;

        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                uint256 milestoneId = milestoneIds[merchantId][appId][customer][contractId][i];
                Milestone memory milestone = milestones[merchantId][appId][customer][contractId][milestoneId];
                if (milestone.status == MILESTONE_STATUS_CREATED || milestone.status == MILESTONE_STATUS_REQUEST_PAYLESS) {
                    allow = false;
                    break;
                }
            }
        }
        require(allow == true, "GetdoneEscrow: contract does not allow to end");

        bool isTalent = contractInfo.talent == sender;
        bool isCustomer = contractInfo.customer == sender;

        if(!contractInfo.isEndCustomer && !contractInfo.isEndTalent) {
            if (isCustomer) {
                contractInfo.isEndCustomer = true;
                emit ContractEnded(contractInfo.merchantId, contractInfo.appId, contractInfo.contractId, sender, 0, contractInfo.erc20, false, true);
            } else if (isTalent) {
                contractInfo.isEndTalent = true;
                emit ContractEnded(contractInfo.merchantId, contractInfo.appId, contractInfo.contractId, sender, 0, contractInfo.erc20, true, false);
            }
        } else if(!isAccept) {
                contractInfo.isEndCustomer = false;
                contractInfo.isEndTalent = false;
                emit ContractEndingDeclined(merchantId, appId, contractId, sender, 0, contractInfo.erc20, false, false);
        } else {
            require(((isTalent && !contractInfo.isEndTalent ) || (isCustomer && !contractInfo.isEndCustomer )), "GetdoneEscrow: Contract is already end");
            uint256 amountRefund = contractInfo.deposit;
            amountRefund = amountRefund + updateMilestoneBalance(contractInfo.merchantId, contractInfo.appId, contractInfo.customer, contractInfo.contractId);

            contractInfo.isEndCustomer = true;
            contractInfo.isEndTalent = true;
            contractInfo.deposit = 0;
            contractInfo.status = CONTRACT_STATUS_ENDED;
            if (amountRefund > 0) {
                contractInfo.refund = contractInfo.refund + amountRefund;
                IGetdoneBanker(contractInfo.banker).send(customer, amountRefund, contractInfo.erc20);
            }
            emit ContractEnded(contractInfo.merchantId, contractInfo.appId, contractInfo.contractId, sender, amountRefund, contractInfo.erc20, true, true);
        }
    }

    function depositContract(uint256 merchantId, uint256 appId, uint256 contractId, address talent, uint256 price, address erc20, uint256 orderId, address sender) 
        public
        payable
        whenNotPaused
        nonReentrant
        returns(address)
    {
        address _customer = _msgSender();
        bool isExnteralCaller = hasRole(DISTRIBUTOR_ROLE, _msgSender()) && sender != address(0);
        if(isExnteralCaller) {
            _customer = sender;
        }
        
        require(erc20Whitelist[merchantId][erc20], "GetdoneEscrow: erc20 must be in whitelist");
        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require(isEnd(merchantId, appId, contractId, _customer) == false, "GetdoneEscrow: contract has been ended");
        require(isDisputation(merchantId, appId, contractId, _customer) == false, "GetdoneEscrow: contract has disputation");
        require(price > 0, "GetdoneEscrow: price must be greater than 0");

        ContractInfo storage contractInfo = contractInfos[merchantId][appId][_customer][contractId];

        if (contractInfo.init == true) {
            require(contractInfo.erc20 == erc20, "GetdoneEscrow: Erc20 can not change");
            require(contractInfo.customer == _customer, "GetdoneEscrow: Cannot deposit contract");
        }

        // create banker
        if(contractInfo.banker == address(0)) {
            address _banker = bankerAddress.clone();
            IGetdoneBanker(_banker).initialize();
            contractInfo.banker = _banker;
        }

        if (!isExnteralCaller) {
            if (erc20 == address(0)) {
                require(msg.value == price, "GetdoneEscrow: deposit amount is not enough");
                // payable(contractInfo.banker).transfer(msg.value);
                (bool success, bytes memory data) = contractInfo.banker.call{value: msg.value}("");
                emit BankerResponse(success, data);
            } else {
                IERC20Upgradeable(erc20).safeTransferFrom(_customer, contractInfo.banker, price);
            }
        }
        

        if (contractInfo.init == false) {
            contractInfo.merchantId = merchantId;
            contractInfo.appId = appId;
            contractInfo.contractId = contractId;
            contractInfo.customer = _customer;
            contractInfo.talent = talent;
            contractInfo.erc20 = erc20;
            contractInfo.deposit = price;
            contractInfo.refund = 0;
            contractInfo.isEndTalent = false;
            contractInfo.isEndCustomer = false;
            contractInfo.status = CONTRACT_STATUS_NEW;
            contractInfo.init = true;
        } else {
            contractInfo.status = contractInfo.status == CONTRACT_STATUS_WITHDRAWN ? CONTRACT_STATUS_NEW : contractInfo.status;
            contractInfo.deposit = contractInfo.deposit + price;
        }
        emit ContractDeposited(contractInfo.merchantId, contractInfo.appId, contractInfo.contractId, orderId, contractInfo.customer, price, erc20);
        return contractInfo.banker;
    }

    function createDisputation(uint256 merchantId, uint256 appId, uint256 contractId, address customer) 
        public
        whenNotPaused
        nonReentrant
    {
        address sender = _msgSender();
        require(validApp(merchantId, appId), "GetdoneEscrow: App is invalid");
        require(disputationAddress != address(0), "GetdoneEscrow: Disputation Contract Address is invalid");

        ContractInfo storage contractInfo = contractInfos[merchantId][appId][customer][contractId];
        
        require((!isDisputation(merchantId, appId, contractId, customer)), "GetdoneEscrow: contract cannot vote disputation");
        require(contractInfo.contractId != 0, "GetdoneEscrow: can not change contract if sender has not made one");
        require((!contractInfo.isEndCustomer || !contractInfo.isEndTalent), "GetdoneEscrow: contract has been ended");
        require((contractInfo.customer == sender || contractInfo.talent == sender), "GetdoneEscrow: can not change contract if sender has not made one");

        uint256 amountRefund = contractInfo.deposit;
        amountRefund = amountRefund + updateMilestoneBalance(contractInfo.merchantId, contractInfo.appId, contractInfo.customer, contractInfo.contractId);

        address disputationBanker = IGetdoneDisputation(disputationAddress).create(merchantId, appId, contractId, customer, sender, amountRefund);

        if (amountRefund > 0) {
            IGetdoneBanker(contractInfo.banker).send(disputationBanker, amountRefund, contractInfo.erc20);
            contractInfo.refund = contractInfo.refund + amountRefund;
        }
        contractInfo.isEndCustomer = true;
        contractInfo.isEndTalent = true;
        contractInfo.deposit = 0;
        contractInfo.dispute = true;
        emit ContractDisputationSent(merchantId, appId, contractId, amountRefund, sender, contractInfo.talent == sender, contractInfo.customer == sender);
    }
    
    function withdrawContract(uint256 merchantId, uint256 appId, uint256 contractId) 
        public
        whenNotPaused
        nonReentrant
    {
        address customer = _msgSender();
        ContractInfo storage contractInfo = contractInfos[merchantId][appId][customer][contractId];
        require(isEnd(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has been ended");
        require(isDisputation(merchantId, appId, contractId, customer) == false, "GetdoneEscrow: contract has disputation");
        require(milestoneIds[merchantId][appId][customer][contractId].length == 0, "GetdoneEscrow: contract has been ended");
        require(contractInfo.customer == customer, "GetdoneEscrow: can not change sale if sender has not made one");
        
        uint256 refund = contractInfo.deposit;
        if (refund > 0) {
            IGetdoneBanker(contractInfo.banker).send(customer, refund, contractInfo.erc20);
        }
        contractInfo.deposit = 0;
        contractInfo.status = CONTRACT_STATUS_WITHDRAWN;
        emit ContractWithdrawn(merchantId, appId, contractId, customer, refund, contractInfo.erc20);
    }

    function _payout(uint256 merchantId, uint256 appId, uint256 contractId, uint256 milestoneId, address customer,  address receiver, uint256 price, address erc20)
        internal
    {
        address _banker = contractInfos[merchantId][appId][customer][contractId].banker;
        uint256 fee = price * apps[merchantId][appId].fee / ONE_HUNDRED_PERCENT;

        uint256 amount = price - fee;

        if(fee > 0) {
            IGetdoneBanker(_banker).send(apps[merchantId][appId].treasury, fee, erc20);
        }
        if (amount > 0) {
            IGetdoneBanker(_banker).send(receiver, amount, erc20);
        }
        emit Payout(merchantId, appId, contractId, milestoneId, amount, fee, erc20, receiver);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// contracts/GetdoneApp.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract GetdoneApp{

    uint256 constant public MERCHANT_ID_GETDONE = 1;
    uint256 constant public APP_ID_DEFAULT = 1;

    event Erc20WhitelistUpdated(uint256 merchantId, address[] erc20s, bool status);
    event MerchantUpdated(uint256 merchantId, address sender);
    event ApplistUpdated(uint256 merchantId, uint256[] appIds, address treasury, uint256 fee);

    struct App {
        uint256 merchantId;
        uint256 appId;
        address treasury;
        uint256 fee;
    }

    // merchantId => address
    mapping(uint256 => bool) public merchants;

    // merchantId => erc20Address => status
    mapping(uint256 => mapping(address => bool)) public erc20Whitelist;

    // merchantId => appId => App
    mapping(uint256 => mapping(uint256 => App)) public apps;

    function validMerchant(uint256 merchantId) internal view returns (bool) {
        return merchants[merchantId];
    }

    function validApp(uint256 merchantId, uint256 appId) internal view returns (bool) {
        return validMerchant(merchantId) && apps[merchantId][appId].appId != 0;
    }

    function _treasuryWallet(uint256 merchantId, uint256 appId) internal view returns(address) {
        return apps[merchantId][appId].treasury;
    }

    function _updateMerchant(uint256 merchantId)
        internal
    {
        merchants[merchantId] = true;

        emit MerchantUpdated(merchantId, msg.sender);
    }

    function _updateApp(uint256 merchantId, uint256[] memory appIds, address treasury, uint256 fee)
        internal
    {
        require(validMerchant(merchantId), "GetdoneEscrow: Merchant is invalid");

        uint256 length = appIds.length;

        require(length > 0, "GetdoneEscrow: App list is required");

        for (uint256 i = 0; i < length; i++) {
            apps[merchantId][appIds[i]] = App(merchantId, appIds[i], treasury, fee);
        }
        emit ApplistUpdated(merchantId, appIds, treasury, fee);
    }

    function _updateErc20Whitelist(uint256 merchantId, address[] memory erc20s, bool status)
        internal
    {
        require(validMerchant(merchantId), "GetdoneEscrow: Merchant is invalid");
        uint256 length = erc20s.length;
        require(length > 0, "GetdoneEscrow: erc20 list is required");
        for (uint256 i = 0; i < length; i++) {
            erc20Whitelist[merchantId][erc20s[i]] = status;
        }

        emit Erc20WhitelistUpdated(merchantId, erc20s, status);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}