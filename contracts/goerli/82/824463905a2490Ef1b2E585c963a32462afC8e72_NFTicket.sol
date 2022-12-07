// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./libs/NFTreasuryLib.sol";
import "./interfaces/INFTicket.sol";
import "./interfaces/INFTServiceTypes.sol";

contract NFTicket is Ownable, ERC721URIStorage, INFTicket {
    using NFTreasuryLib for NFTreasuryLib.Treasury;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    mapping(address => bool) _whitelist;

    modifier QualifiedServiceProviderOnly(
        address serviceProviderContract,
        uint32 sD
    ) {
        // TODO confirm serviceProvider serves that serviceDescriptor
        isServiceProviderFor(serviceProviderContract, sD);
        _;
    }

    modifier onlyWhiteList(address sender) {
        require(inWhitelist(sender), "not white");
        _;
    }

    function removeWhitelist(address _address) public {
        _whitelist[_address] = false;
    }

    function addWhitelist(address _address) external {
        _whitelist[_address] = true;
    }

    function inWhitelist(address _address) public view returns (bool) {
        return bool(_whitelist[_address]);
    }

    address public immutable ERC20_Token;
    address ticketProcessor;
    // NFTicketLib.TicketLib ticketLib;
    NFTreasuryLib.Treasury treasuryLib;
    Counters.Counter private _tokenIds;

    constructor(
        address _erc20,
        uint32 transactionFee,
        uint32 ratioBase
    ) ERC721("NFTicket", "BLXFT") {
        ERC20_Token = _erc20;
        treasuryLib.TRANSACTIONFEE = transactionFee;
        treasuryLib.ratioBASE = ratioBase;
        treasuryLib.ERC20_Token = _erc20;
        treasuryLib.owner = owner();
        treasuryLib.nfticket = address(this);
    }

    function initProcessor(address _processor) public onlyOwner {
        ticketProcessor = _processor;
    }

    function getTicketProcessor()
        public
        view
        override
        onlyWhiteList(msg.sender)
        returns (address)
    {
        return (ticketProcessor);
    }

    function getMasterWallet()
        public
        view
        onlyWhiteList(msg.sender)
        returns (address)
    {
        return treasuryLib.owner;
    }

    function setMasterWallet(address master) external onlyOwner {
        treasuryLib.owner = master;
    }

    function mintNFTicket(address recipient, Ticket memory _ticket)
        external
        payable
        override
        returns (Ticket memory _ret)
    {
        // TODO require() that reseller is either a registered reseller or serviceProvider;
        uint256 serviceFee;
        uint256 resellerFee;
        uint256 transactionFee;
        _ret = _ticket;
        _ret.tokenID = _tokenIds.current();

        _mint(recipient, _ret.tokenID);
        _setTokenURI(_ret.tokenID, _ret.tokenURI);
        treasuryLib.setTicketData(_ret.tokenID, _ret);
        (serviceFee, resellerFee, transactionFee) = treasuryLib.splitRevenue(
            _ret,
            _ret.price
        );
        emit SplitRevenue(
            _ret.tokenID,
            msg.value,
            serviceFee,
            resellerFee,
            transactionFee
        );
        _tokenIds.increment();

        return (_ret);
    }

    function getTicketData(uint256 _ticketID)
        public
        view
        override
        returns (Ticket memory _t)
    {
        // TODO hb220710 verify calling party is whitelisted for this ticket
        _t = treasuryLib._ticketData[_ticketID];
        return (_t);
    }

    function updateTicketData(uint256 _ticketID, Ticket memory _t) public {
        treasuryLib._ticketData[_ticketID] = _t;
    }

    function presentTicketFeeToPool(
        Ticket memory _t,
        uint256 credits,
        address ERC20Token
    ) public returns (Ticket memory ticket) {
        ticket = treasuryLib.presentTicketFeeToPool(_t, credits, ERC20Token);
        return (ticket);
    }

    function withDrawCredits(
        uint256 _ticketID,
        address erc20Contract,
        uint256 credits,
        address sendTo
    ) external override {
        Ticket memory _t = treasuryLib.getTicketData(_ticketID);
        require(credits <= _t.credits, "insufficient credits");

        emit WithDrawCredits(
            _ticketID,
            erc20Contract,
            credits,
            msg.sender,
            sendTo
        );
    }

    function withDrawERC20(
        uint256 _ticketID,
        address erc20Contract,
        uint256 amountERC20Tokens,
        address sendTo
    ) external override {
        treasuryLib.withDrawERC20(_ticketID, erc20Contract, amountERC20Tokens);

        TransferHelper.safeTransfer(erc20Contract, sendTo, amountERC20Tokens);

        emit WithDrawERC20(
            _ticketID,
            erc20Contract,
            amountERC20Tokens,
            msg.sender,
            sendTo
        );
    }

    function topUpTicket(
        uint256 _ticketID,
        uint256 creditsAdded,
        address erc20Token,
        uint256 numberERC20Tokens
    )
        external
        override
        returns (uint256 creditsAffordable, uint256 chargedERC20)
    {
        uint32 status;
        (status, creditsAffordable, chargedERC20) = treasuryLib.topUpTicket(
            _ticketID,
            creditsAdded,
            erc20Token,
            numberERC20Tokens
        );

        Ticket memory _t = treasuryLib.getTicketData(_ticketID);
        TransferHelper.safeTransferFrom(
            erc20Token,
            msg.sender,
            address(this),
            numberERC20Tokens
        );

        emit IncomingFunding(
            _ticketID,
            erc20Token,
            msg.sender,
            address(this),
            _t.credits,
            _t.price,
            _t.serviceDescriptor
        );

        return (creditsAffordable, chargedERC20);

        //TODO JAN: add event: TopUpTicket(uint256 tokenID, uint256 creditsAdded, address erc20Contract, uint256 numberERC20Tokens, uint256 creditsAffordable, uint256 chargedERC20);
    }

    function updateServiceType(uint256 ticketID, uint32 serviceDescriptor)
        public
        override
        QualifiedServiceProviderOnly(msg.sender, serviceDescriptor)
        returns (uint256 _sD)
    {
        Ticket memory ticket = getTicketData(ticketID);
        _sD = treasuryLib.updateServiceType(ticket, serviceDescriptor);
        return (_sD);
    }

    function presentCertificateRepurchase(address sender, Ticket memory _t)
        public
    {
        treasuryLib.presentCertificateRepurchase(sender, _t);
    }

    function getResellerPoolSize(address serviceProvider)
        external
        view
        returns (
            /* , address reseller TODO provider:reseller m:n instead of 1:1 */
            uint256 poolSize
        )
    {
        return (treasuryLib.getResellerPoolSize(serviceProvider));
    }

    function getTransactionPoolSize() external view override returns (uint256) {
        return (treasuryLib.getTransactionPoolSize());
    }

    function getServiceProviderPoolSize(address serviceProvider)
        external
        view
        override
        returns (uint256 poolSize)
    {
        return (treasuryLib.getServiceProviderPoolSize(serviceProvider));
    }

    function getTotalTicketPoolSize() external view override returns (uint256) {
        return (treasuryLib.getTotalTicketPoolSize());
    }

    function getTicketBalance(uint256 tokenID)
        external
        view
        override
        returns (uint256)
    {
        return (treasuryLib.getTicketBalance(tokenID));
    }

    /*
    function consumeCredits(
        address serviceProvider,
        uint256 _tokenID,
        uint256 _consumeCredits
    )
        external
        override
        returns (uint256 creditsConsumed, uint256 creditsRemain)
    {
        require(
            treasuryLib._ticketData[_tokenID].credits - _consumeCredits >= 0,
            "not enough credits left on Ticket"
        );

        uint256 _serviceProvider = uint256(uint160(serviceProvider));
        require(
            msg.sender ==
                treasuryLib.serviceProvidersReseller.get(
                    uint256(_serviceProvider)
                ),
            "require a valid reseller"
        );

        creditsConsumed = INFTServiceProvider(serviceProvider).consumeCredits(
            treasuryLib._ticketData[_tokenID],
            _consumeCredits
        );

        creditsRemain = treasuryLib.consumeCredits(_tokenID, creditsConsumed);
        emit ConsumedCredits(_tokenID, creditsConsumed, creditsRemain);
        return (creditsConsumed, creditsRemain);
    }
    */

    function registerResellerServiceProvider(
        address serviceProvider,
        address reseller,
        address resellerWallet
    ) external override onlyWhiteList(msg.sender) returns (uint16 status) {
        status = 201;
        require(
            treasuryLib.isRegisteredServiceProvider(serviceProvider),
            "SP not regd"
        );
        status = treasuryLib.registerServiceReseller(
            serviceProvider,
            reseller,
            resellerWallet
        );
    }

    function registerServiceProvider(
        address serviceProvider,
        uint32 serviceDescriptor,
        address serviceProviderWallet
    ) external override onlyWhiteList(msg.sender) returns (uint16 status) {
        status = 201;
        status = treasuryLib.registerServiceProvider(
            serviceProvider,
            serviceDescriptor,
            serviceProviderWallet
        );
        emit RegisterServiceProvider(
            serviceProvider,
            serviceDescriptor,
            status
        );
    }

    function getTreasuryOwner() public view override returns (address owner) {
        return (treasuryLib.owner);
    }

    function getCompanyDescriptor(address serviceProvider)
        external
        view
        returns (uint32 descriptor)
    {
        descriptor = treasuryLib.getCompanyDescriptor(serviceProvider);
    }

    function getReseller(address serviceProvider)
        external
        view
        returns (address contractAddress, address walletAddress)
    {
        contractAddress = treasuryLib.serviceProvidersReseller[serviceProvider];
        walletAddress = treasuryLib
            .serviceProviderAccount[serviceProvider]
            .resellerWallet;
    }

    function isServiceProviderFor(
        address serviceContract,
        uint32 /* serviceDescriptor */
    ) public view returns (bool _isServiceProviderFor) {
        _isServiceProviderFor = false;

        if (isServiceProvider(serviceContract)) {
            // if providesService(serviceContract, serviceDescriptor) TODO - really need to figure out data model and data flow for Ticket and Service
            _isServiceProviderFor = true;
        } else {
            _isServiceProviderFor = false;
        }

        return (_isServiceProviderFor);
    }

    function isServiceProvider(address sContract) public view returns (bool) {
        return (treasuryLib.getCompanyDescriptor(sContract) != 0);
    }

    function getServiceProvider(uint32 companyDescriptor)
        public
        view
        returns (address contractAddress, address walletAddress)
    {
        contractAddress = treasuryLib._providers[companyDescriptor];
        require(contractAddress != address(0), "undef SP");
        walletAddress = treasuryLib
            .serviceProviderAccount[contractAddress]
            .serviceProviderWallet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./INFTServiceTypes.sol";   
/**
 * Interface of NFTicket
 */

 
interface INFTicket {
    function mintNFTicket(address recipient, Ticket memory _ticket)
        external
        payable 
        returns (Ticket memory);

    function updateServiceType(uint256 ticketID, uint32 serviceDescriptor)
        external
        returns(uint256 _sD);
    
    function withDrawCredits(uint256 _ticketID, address erc20Contract, uint256 credits, address sendTo)
        external;
        
    function withDrawERC20(uint256 _ticketID, address erc20Contract, uint256 amountERC20Tokens, address sendTo)
        external;
    function topUpTicket(uint256 tokenID, uint256 creditsAdded, address erc20Contract, uint256 numberERC20Tokens)
        external returns(uint256 creditsAffordable, uint256 chargedERC20);

    function registerServiceProvider(address serviceProvider, uint32 serviceDescriptor, address serviceProviderWallet) 
        external returns(uint16 status);
    function registerResellerServiceProvider(address serviceProvider, address reseller, address resellerWallet)
        external returns(uint16 status); 

    /*
    function consumeCredits(address serviceProvider, uint256 _tokenID, uint256 credits)
        external 
        returns(uint256 creditsConsumed, uint256 creditsRemain);
    */

    function getTransactionPoolSize() external view returns (uint256);

    function getServiceProviderPoolSize(address serviceProvider)
        external
        view
        returns (uint256 poolSize);

    function getTotalTicketPoolSize() 
        external 
        view 
        returns (uint256); 

    function getTicketData(uint256 _ticketID)
        external
        view
        returns (Ticket memory);

    function getTicketBalance(uint256 tokenID) 
        external 
        view 
        returns (uint256); 

    function getTreasuryOwner()
        external
        returns(address);
    
    function getTicketProcessor()
        external
        returns(address);
    
    
    event IncomingERC20(
        uint256 indexed tokenID,
        address indexed ERC20,
        uint256 amountERC20Tokens,
        address sender,
        address owner,
        uint32  indexed serviceDescriptor
    );

    event IncomingFunding(
        uint256 indexed tokenID,
        address indexed ERC20,
        address sender,
        address owner,
        uint256 creditsAdded,
        uint256 tokensAdded,
        uint32  indexed serviceDescriptor
    );

    event WithDrawCredits(
        uint256 indexed tokenID,
        address indexed erc20Contract,
        uint256 amountCredits,
        address indexed from,
        address to 
    );
    event WithDrawERC20(
        uint256 indexed tokenID,
        address indexed erc20Contract,
        uint256 amountERC20Tokens,
        address indexed from,
        address to 
    );

    event TicketSubmitted(
        address indexed _contract,
        uint256 indexed ticketID,
        uint256 indexed serviceType,
        uint256 deductedFee
    );
    event SplitRevenue(
        uint256 indexed newTicketID,
        uint256 value,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256 transactionFee
    );
    event SchemaRegistered(string name, DataSchema schema);
    event ConsumedCredits(
        uint256 indexed _tID,
        uint256 creditsConsumed,
        uint256 creditsRemain
    );
    event RegisterServiceProvider(
        address indexed serviceProvideContract,
        uint32 indexed serviceDescriptor,
        uint16 status
    );
    event WrongSender(
        address sender,
        address expectedSender,
        string message
    );
    event InsufficientPayment(
        uint256 value,
        uint256 credits,
        uint256 pricePerCredit
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./TransferHelper.sol";
import "../interfaces/INFTServiceTypes.sol";
import "../interfaces/INFTicket.sol";

library NFTreasuryLib {
    using SafeMath for uint;

    event ExceptionFeesInsufficientValue(
        uint256 value,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256 transactionFee
    );

    struct RevenuePool {
        address resellerWallet; // reseller's wallet
        address serviceProviderWallet; // service provider's wallet
        uint256 serviceTicketPool; // total unclaimed serviceFees
        uint256 resellerPool; // acc revenue pool for reseller
        uint256 serviceProviderPool; // acc revenue pool for service provider
    }

    enum erc20 {BLXM, USDC, EWT, CELO, cUSD}

    // TODO prepare for multi-token logic
    struct poolsByToken {
        string tokenTicker;
        address contractAddress;
        mapping(address => uint256) contractBalance; // total liquid balance
        mapping(address => uint256) transactionPool;
        mapping(address => RevenuePool) serviceProviderAccount;
        mapping(uint256 => uint256) remainingTicketBalance;
    }

    struct Treasury {
        // these values are initiated in NFTicket constructor{}
        address owner;
        address nfticket;
        address ERC20_Token;
        uint32 TRANSACTIONFEE; // promil, i.e. 1.5%
        uint32 ratioBASE;
        uint256 _totalTicketPool;


        
        // main accounts by role in NFTicket
        mapping(address => uint256) _contractBalance; // total liquid balance
        mapping(address => uint256) transactionPool;
        mapping(address => RevenuePool) serviceProviderAccount;
        mapping(uint256 => uint256) remainingTicketBalance; // mapping of ticketID to balance

        /*
         * TODO
         * only have 1:1 mapping between reseller and provider for now.
         * Need to extends this to m:n or at least
         * 1:n 1 reseller having several service provider
         */
        mapping(address => address) resellersServiceProvider;
        mapping(address => address) serviceProvidersReseller;
        mapping(uint32 => address) _providers;
        mapping(address => uint32) _companyDescriptors;
        mapping(uint256 => Ticket) _ticketData;
    }


    function init(
        Treasury storage _treasury,
        address _nfticket
    )
        public
    {
        _treasury.nfticket = _nfticket;
        // TODO multi-token struct poolsByToken[uint256(erc20.BLXM)].contractBalance = _treasury._contractBalance;

    }
    function consumeCredits(
        Treasury storage _t,
        uint256 tokenID,
        uint256 creditsConsumed
    ) public returns (uint256 remainingCredits) {
        _t._ticketData[tokenID].credits -= creditsConsumed;
        remainingCredits = _t._ticketData[tokenID].credits;
    }

    function getResellerWallet(
        Treasury storage _treasury,
        address serviceProviderContract
    ) 
        public 
        view
        returns (address _wallet) 
    {
        return (
            _treasury.serviceProviderAccount[serviceProviderContract].resellerWallet
        );
    }

    function getTicketData(Treasury storage _treasury, uint256 tokenID)
        public
        view
        returns(Ticket memory _t)
    {
        _t = _treasury._ticketData[tokenID];
        return(_t);
    }
    function getServiceProviderWallet(
        Treasury storage _treasury,
        address serviceProviderContract
    ) 
        public 
        view
        returns (address _wallet) 
    {
        return (
            _treasury
                .serviceProviderAccount[serviceProviderContract]
                .serviceProviderWallet
        );
    }

    function getResellerPoolSize(
        Treasury storage _treasury,
        address serviceProvider
    ) internal view returns (uint256 poolSize) {
        return (_treasury.serviceProviderAccount[serviceProvider].resellerPool);
    }

    function getTransactionPoolSize(Treasury storage _treasury)
        internal
        view
        returns (uint256 poolSize)
    {
        return (_treasury.transactionPool[_treasury.owner]);
    }

    function getServiceProviderPoolSize(
        Treasury storage _treasury,
        address serviceProvider
    ) internal view returns (uint256 poolSize) {
        return (
            _treasury.serviceProviderAccount[serviceProvider].serviceProviderPool
        );
    }

    function setTicketData(
        Treasury storage _treasury,
        uint256 newTicketID,
        Ticket memory _ticket
    ) internal {
        _treasury._ticketData[newTicketID] = _ticket;
    }

    function getTotalTicketPoolSize(Treasury storage _treasury)
        internal
        view
        returns (uint256 poolSize)
    {
        return (_treasury._totalTicketPool);
    }

    function getTicketBalanceByERC20(Treasury storage _treasury, uint256 tokenID, address)
        internal
        view
        returns (uint256)
    {
        return (_treasury.remainingTicketBalance[tokenID]);
    }

    function getTicketBalance(Treasury storage _treasury, uint256 tokenID)
        internal
        view
        returns (uint256)
    {
        return (_treasury.remainingTicketBalance[tokenID]);
    }

    /*********
    *
    * validate ticket types.
    *
    ***********/
    function isCertificate(Treasury storage, Ticket memory _t) 
        public
        pure
        returns(bool _isCertificate)
    {

        _isCertificate = ((_t.serviceDescriptor & IS_CERTIFICATE) == IS_CERTIFICATE);
        return(_isCertificate);
    }
    function isTicket(Treasury storage, Ticket memory _t) 
        public
        pure
        returns(bool _isTicket)
    {

        _isTicket = ((_t.serviceDescriptor & IS_TICKET) == IS_TICKET); 
        return(_isTicket);
    }
    function isCashVoucher(Treasury storage, Ticket memory _t) 
        public
        pure
        returns(bool _isCashVoucher)
    {
        _isCashVoucher = ((_t.serviceDescriptor & CASH_VOUCHER) == CASH_VOUCHER);
    }
    // end of ticket type validation
    
    function updateServiceType(Treasury storage _t, Ticket memory ticket, uint32 serviceDescriptor)
        public
        returns(uint32) 
    {
        uint32 currentSD = ticket.serviceDescriptor;
        uint32 currentCompany =  currentSD % 0x400; // current company descriptor
        uint32 newCompany = serviceDescriptor % 0x400;
        if (currentCompany != newCompany) {
            string memory _msg = "Company=";
            _msg = string(abi.encodePacked(_msg, Strings.toString(newCompany), " not allowed to change services for company=", Strings.toString(newCompany)));
            require(currentCompany == newCompany, _msg);
        }
        ticket.serviceDescriptor = serviceDescriptor;
        setTicketData(_t, ticket.tokenID, ticket);

        return(serviceDescriptor ^ newCompany); //  XOR of equal values should return 0
    }
    
    function withDrawERC20(Treasury storage _treasury, uint256 _ticketID, address, uint256 amountERC20Tokens)
        public
        returns(Ticket memory)
    {
    
        uint256 currentBalance = getTicketBalance(_treasury, _ticketID);
        uint256 currentTicketPool = _treasury._totalTicketPool;

        Ticket memory _t = getTicketData(_treasury, _ticketID);
        require(amountERC20Tokens <= currentBalance, "insufficient ERC20 tokens on NFTicket");
        reduceTicketBalance(_treasury, _t, amountERC20Tokens);

        uint256 newBalance = getTicketBalance(_treasury, _ticketID);
        uint256 newTicketPool = _treasury._totalTicketPool;
        require(currentBalance.sub(amountERC20Tokens) == newBalance, "ticket balance not correctly reduced");
        require(currentTicketPool.sub(amountERC20Tokens) == newTicketPool, "ticket pool not correctly reduced");

        if ( isCashVoucher(_treasury, _t )) {
            return(_t);
        } else {
            uint256 reducedBalance = getTicketBalance(_treasury, _ticketID);
            uint256 reduceCreditsBy = reducedBalance.div(_t.pricePerCredit);
            if(reduceCreditsBy >= _t.credits) {
                _t.credits = 0;
            } 
            else {
                _t.credits = _t.credits.sub(reduceCreditsBy);
            }
        }
        
        setTicketData(_treasury, _ticketID, _t);
        return(_t);
    }

    function addTicketBalance(Treasury storage _treasury, Ticket memory ticket, uint256 increaseBalanceBy) 
        internal
    {
        _treasury.remainingTicketBalance[ticket.tokenID] += increaseBalanceBy;
        _treasury._totalTicketPool += increaseBalanceBy;
    }

    function reduceTicketBalance(Treasury storage _treasury, Ticket memory ticket, uint256 reduceBalanceBy) 
        internal
    {
        _treasury.remainingTicketBalance[ticket.tokenID] -= reduceBalanceBy;
        _treasury._totalTicketPool -= reduceBalanceBy;
    }

     function _splitRevenue(Treasury storage _treasury, Ticket memory _ticket, uint256 serviceFee, uint256 resellerFee, uint256 transactionFee) 
        public
        {
            // Treasury keeps TX fees
        _treasury.transactionPool[_treasury.owner] += transactionFee;

        if (isCashVoucher(_treasury, _ticket)) {
            require( (_ticket.pricePerCredit == 0) &&  (_ticket.credits == 0), "CASH_VOUCHER MUST have ppC == credits == 0");
            distributeTicketRevenueToPool(_treasury, _ticket, serviceFee, resellerFee, transactionFee);
        } else if (isCertificate(_treasury, _ticket)) {
            distributeCertificateRevenueToPool(_treasury, _ticket, serviceFee, resellerFee, transactionFee);
        } else if (isTicket(_treasury, _ticket)) {
            distributeTicketRevenueToPool(_treasury, _ticket, serviceFee, resellerFee, transactionFee);
        } else {
            string memory _msg;

            _msg = "service Descriptor ";
            _msg = string(
                abi.encodePacked(
                    _msg,
                    Strings.toHexString(_ticket.serviceDescriptor),
                    " neither CERT nor TICKET nor CASH_VOUCHER"
                )
            );
            require ( (isCertificate(_treasury, _ticket) || isTicket(_treasury, _ticket) || isCashVoucher(_treasury, _ticket)), _msg );
        }

        setTicketData(_treasury, _ticket.tokenID, _ticket);
    }

    /*****************************************
     *
     * TODO: this should be called once to determine the main values
     * calculate values and pass the actual splitting of revenue to _splitRevenue
     * strong case to be made to use ERC155 here, because all tokens with the same ID can share same formula
     * but we are free to create different token classes identified by their tokenIDs
     *
     ******************************************/
    function splitRevenue(
        Treasury storage _treasury,
        Ticket memory _ticket,
        uint256 totalIncome
        ) internal returns (uint256, uint256 , uint256 ) {
        uint256 resellerFee = _ticket.resellerFee; // e.g. 100 on a base of 1.000 -> 0.1 = 10%
        uint256 f = _ticket.resellerFee.add(_ticket.serviceFee); 
        f = f.add(_ticket.transactionFee); // full share --> BASE
        uint256 v = uint256(_treasury.ratioBASE).mul(1 ether);
        string memory _msg;
        if ( f !=  v ) {
            _msg = "resellerFee= ";
            _msg = string(abi.encodePacked(_msg,Strings.toString(_ticket.resellerFee)," + serviceFee=", 
                Strings.toString(_ticket.serviceFee),
                " != txBASE=",(Strings.toString(_treasury.ratioBASE * (1 ether)))));
            require(f == v, _msg);
        }
        // total transaction fee = _treasury.TRANSACTIONFEE * (f = resellerFee + serviceFee)
        uint256 transactionShare = _ticket.price.mul(_treasury.TRANSACTIONFEE); // e.g. 3.000 = 300 * 10 on a BASE of 1.000
        transactionShare = transactionShare.div(_treasury.ratioBASE); // 3 <= price=300 * TXfee=10 / BASE=1000
        _ticket.transactionFee = uint256(_treasury.TRANSACTIONFEE).mul(1 ether);
       
        /****
        *
        * ALL EXAMPLES GIVEN: price = 300; txFEE = 10 ; txBASE = 1.000
        *  Calculate absolute (serviceShare) and relative (serviceFee) by subtracting relative txFee
        *  where:
            price * serviceFee = serviceShare 
        *
        *****/

        uint256 serviceShare = _ticket.serviceFee.mul(_ticket.price); // e.g. 270.000 = 900 * 300 
        serviceShare = serviceShare.div(1 ether).div(_treasury.ratioBASE); // e.g. 270 = price * _ticket.serviceFee / txBASE, i.e. share before txFee
        uint256 transactionCost = serviceShare.mul(_treasury.TRANSACTIONFEE); // 
        transactionCost = transactionCost.div(_treasury.ratioBASE); // e.g. 2.7 = 270 * 10/1000
        serviceShare -= transactionCost; // e.g. 267.3 = 270 - 2.7; i.e. NET serviceShare AFTER txFEE
        uint256 serviceFee = _ticket.serviceFee.mul(_treasury.TRANSACTIONFEE); // e.g. 9.000
        _ticket.serviceFee -= serviceFee.div(_treasury.ratioBASE); // e.g 891 = 900 - 9{=9.000/txBASE=1.000}; so, e.g price=300 * 891/1.000=txFEE => serviceShare=267.3

        /****
        *
        *  Calculate absolute (resellerShare) and relative (resellerFee) reseller's share
        *  where:
            price * resellerFee = resellerShare
        *
        *****/
        uint256 resellerShare = _ticket.resellerFee.mul(_ticket.price); // e.g. 30.000 = 100 * 300
        resellerShare = resellerShare.div(1 ether).div(_treasury.ratioBASE); // e.g 30 = price * _ticket.resellerFee / txBASE, i.e. share before txFEE
        transactionCost = resellerShare.mul(_treasury.TRANSACTIONFEE); // e.g. 30 * 10 = 300
        transactionCost = transactionCost.div(_treasury.ratioBASE); // e.g. 0.3 = 300 / 1.000 
        resellerShare -= transactionCost; // e.g. 29.7 = 30 - 0.3; i.e. NET serviceShare AFTER txFEE
        resellerFee = _ticket.resellerFee.mul(_treasury.TRANSACTIONFEE); // e.g. 1.000
        _ticket.resellerFee -= resellerFee.div(_treasury.ratioBASE); // e.g. 99 = 100 - 1{=1.000/txBASE=1.000}; so, e.g price=300 * 99/1.000=txFEE => resellerShare=29.7

        /********* START Treasury magicK ***********
         *
         * update pools and allowances
         * bracket by verifying distribution BEFORE and AFTER
         *
         ********************************************/
        verifyAllowances(_treasury, _ticket, totalIncome, serviceShare, resellerShare, transactionShare);
        _splitRevenue(_treasury, _ticket, serviceShare, resellerShare, transactionShare);
        if ( ! isCashVoucher(_treasury, _ticket)) {
            require(_ticket.credits != 0, "credits zero in splitRevenue && ! isCashVoucher()");
            _ticket.pricePerCredit = _ticket.price.div(serviceFee);
        } else {
            require(((_ticket.credits == 0) && (_ticket.pricePerCredit == 0)), "isCashVoucher BUT: credits OR ppC != 0 ");
        }
        verifyAllowances(_treasury, _ticket, totalIncome, serviceShare, resellerShare, transactionShare);
        /********* END of Treasury magicK ***********/
        
        return (serviceShare, resellerShare, transactionShare);
    }

    function fundCashVoucher(Treasury storage _treasury, Ticket memory _ticket, address, uint256 erc20Tokens)
        public
        returns(uint256 addedTokens)
    {
        uint256 resellerFee = 0;
        uint256 transactionFee = 0;


        if ( ! isCashVoucher(_treasury, _ticket) ) {
            string memory _msg;

            _msg = "SP_DESCRIPTOR ";
            _msg = string(abi.encodePacked(_msg, Strings.toString(_ticket.serviceDescriptor), " is not a CASH_VOUCHER "));
            require(false, _msg); // if condition has established isCashVoucher() == false
        }
        require(((_ticket.credits == 0) && (_ticket.pricePerCredit == 0)) , "require credits == pricePerCredit == 0 for CASH_VOUCHER");

        uint256 ticketBalanceBefore = _treasury.remainingTicketBalance[_ticket.tokenID];

        _splitRevenue(_treasury, _ticket, erc20Tokens, resellerFee, transactionFee);
        uint256 ticketBalanceAfter = _treasury.remainingTicketBalance[_ticket.tokenID];
        require(ticketBalanceAfter.sub(ticketBalanceBefore) == erc20Tokens);

        return(erc20Tokens);
    }


    function topUpTicket(Treasury storage _treasury, uint256 _ticketID, uint256 credits, address erc20Contract, uint256 erc20Tokens) 
        public
        returns(uint32 status, uint256 creditsAffordable, uint256 chargedERC20)
    {
         status = 200;
         // update ticket fees
         uint256 ticketBalanceBefore = _treasury.remainingTicketBalance[_ticketID];
         Ticket memory _ticket = _treasury._ticketData[_ticketID];
         uint256 resellerFee;
         uint256 transactionFee;
         string memory _msg;

         
         // IF THIS TRUE THEN go to fundTicket and RETURN FROM HERE
         if ( isCashVoucher(_treasury, _ticket)) {
            require(credits == 0, 'CASH_VOUCHER cannot be loaded with credit points');
            uint256 addedTokens = fundCashVoucher(_treasury, _ticket, erc20Contract, erc20Tokens); // credits == 0; ppC == 0
            return(201, 0, addedTokens);
         }
         
         _msg = 'Ticket has ppC == 0; SP_DESCRIPTOR = ';
         _msg = string(abi.encodePacked(_msg, Strings.toString(_ticket.serviceDescriptor)));
         require(! (_ticket.pricePerCredit == 0), _msg);
         // CASH_VOUCHER RETURNs BEFORE THIS
         
         require(credits != 0, 'cannot top up 0 credits');
         creditsAffordable = erc20Tokens.div(_ticket.pricePerCredit);

         // SP_DESCRIPTOR != CASH_VOUCHER
         if (creditsAffordable >= credits ) {
            if( creditsAffordable > credits ) {
                creditsAffordable = credits;
            }
            // TODO charge credits and return possible Overpay
            require( _ticket.pricePerCredit != 0, "ppC needs to be != 0");
            chargedERC20 = creditsAffordable.mul(_ticket.pricePerCredit);

            _ticket.credits += creditsAffordable;
            resellerFee = 0;
            transactionFee = 0;
         } else {
            _msg = "insufficient credits=";
            _msg = string(abi.encodePacked(_msg,Strings.toString(credits), " can afford only=",Strings.toString(creditsAffordable), " ppC=", Strings.toString(_ticket.pricePerCredit)));
            require(false, _msg);
            status = 400;
         }

        _splitRevenue(_treasury, _ticket, chargedERC20, resellerFee, transactionFee);
        uint256 ticketBalanceAfter = _treasury.remainingTicketBalance[_ticketID];
        if ( ticketBalanceAfter.sub(ticketBalanceBefore) != chargedERC20 ) {
            _msg = "ticketBalanceAfter=";
            _msg = string(abi.encodePacked(_msg,Strings.toString(ticketBalanceAfter), " - ticketBalanceBefore=", Strings.toString(ticketBalanceBefore), " != chargedERC20=", Strings.toString(chargedERC20)));
            require(ticketBalanceAfter.sub(ticketBalanceBefore) == chargedERC20, _msg);
        }
        /*****
        *
        * pricePerCredit is a derived value. It represents net balance divided by number of credits
        * We need to do it this way to always be able to charge exactly and safely by credits without risk of overrun.
        *
        *******/
        _ticket.pricePerCredit = ticketBalanceAfter.div(_ticket.credits);
        verifyAllowances(_treasury, _ticket, chargedERC20, chargedERC20, resellerFee, transactionFee);
        uint256 ticketBalance = _treasury.remainingTicketBalance[_ticket.tokenID];
        if (_ticket.pricePerCredit.mul(uint256(_ticket.credits)) != ticketBalance) {
            _msg = "ppC=";
            _msg = string(abi.encodePacked(_msg, Strings.toString(_ticket.pricePerCredit), " != ticketBalance=", Strings.toString(ticketBalance.div(_ticket.credits))));
            require(_ticket.pricePerCredit == ticketBalance.div(_ticket.credits), _msg);
        }

        return(status, creditsAffordable, chargedERC20);

    }

   

    function updateTicketPools(
        Treasury storage _treasury,
        address serviceProvider,
        Ticket memory ticket,
        uint256 serviceFee,
        uint256 resellerFee
    ) public {
        bool scenarioExists = false;
        if ( isCertificate(_treasury, ticket) && (! isCashVoucher(_treasury, ticket))) { // not sure whether there is a scenario where isCertificate && isCashVoucher both true 
        /*****
        *
        * certificates are proof of ownership
        * proof of ownership is immediately transferred vs. becoming credits to drawn down in tickets
        * this means the service provider is immediately credited with his share of the ticket price
        *
        ********/
        scenarioExists = true;
        addTicketBalance(_treasury, ticket, serviceFee);
        address resellerWallet = getResellerWallet(_treasury, serviceProvider);
        address serviceProviderWallet = getServiceProviderWallet(_treasury, serviceProvider);
        // serviceProvider share
        _treasury.serviceProviderAccount[serviceProvider].serviceProviderPool 
            += serviceFee;
        TransferHelper.safeApprove(_treasury.ERC20_Token, serviceProviderWallet,
            _treasury.serviceProviderAccount[serviceProvider].serviceProviderPool);

        // reseller share
        _treasury.serviceProviderAccount[serviceProvider].resellerPool += resellerFee;
        TransferHelper.safeApprove(_treasury.ERC20_Token, resellerWallet, 
            _treasury.serviceProviderAccount[ticket.serviceProvider].resellerPool);

        } else if (isTicket(_treasury, ticket) || isCashVoucher(_treasury, ticket) ) {
            scenarioExists = true;
            addTicketBalance(_treasury, ticket, serviceFee);
            _treasury.serviceProviderAccount[serviceProvider].serviceTicketPool += serviceFee;
            _treasury.serviceProviderAccount[serviceProvider].resellerPool += resellerFee;
            
            TransferHelper.safeApprove(_treasury.ERC20_Token, _treasury.owner, 
                _treasury.transactionPool[_treasury.owner] +
                _treasury.serviceProviderAccount[serviceProvider].serviceTicketPool
            );
        // reseller fee for reseller
        address resellerWallet = getResellerWallet(_treasury, serviceProvider);
        string memory _msg = "resellerWallet for SP=";
        _msg = string(abi.encodePacked(_msg, Strings.toString(uint160(serviceProvider))," is ", Strings.toString(uint160(resellerWallet))));
        require(resellerWallet != address(0), _msg);
        TransferHelper.safeApprove(_treasury.ERC20_Token, resellerWallet, 
            _treasury.serviceProviderAccount[serviceProvider].resellerPool);
        }

        require(scenarioExists, 'updateTPools: unknown scenario');
    }

    function distributeTicketRevenueToPool(
        Treasury storage _treasury,
        Ticket memory _ticket,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256
    ) public {
        updateTicketPools(_treasury, _ticket.serviceProvider, _ticket, serviceFee, resellerFee);
        // minting fee for NFTicket MSC
        
    }

    function distributeCertificateRevenueToPool(
        Treasury storage _treasury,
        Ticket memory _ticket,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256
    ) 
        public 
    {
        updateTicketPools(_treasury, _ticket.serviceProvider, _ticket, serviceFee, resellerFee);
    }

    function presentTicketFeeToPool(Treasury storage _treasury, Ticket memory _t, 
        uint256 credits, address ERC20Token) 
        internal 
        returns(Ticket memory)
    {
        string memory _msg;
        address serviceProviderWallet = getServiceProviderWallet(_treasury, _t.serviceProvider);

        uint256 originalServiceProviderPool = getServiceProviderPoolSize(_treasury, _t.serviceProvider);
        uint256 originalServiceProviderAllowance = IERC20(ERC20Token).allowance(address(this), serviceProviderWallet);
        if (originalServiceProviderPool != originalServiceProviderAllowance) {
            _msg = "Service Provider pool and allowance differ ";
            _msg = string(abi.encodePacked(_msg,Strings.toString(originalServiceProviderPool)," ", Strings.toString(originalServiceProviderAllowance)));
            require(originalServiceProviderPool == originalServiceProviderAllowance, _msg);
        }

        require(_t.credits != 0, "cannot credit ticket with remaining credit of 0");
        uint256 valueCredited = ( _treasury.remainingTicketBalance[_t.tokenID] * credits) / _t.credits;
        require(_treasury.remainingTicketBalance[_t.tokenID] >= valueCredited, "tokenBalance insufficient");
        require(_treasury.serviceProviderAccount[_t.serviceProvider].serviceTicketPool >= valueCredited, 
            "serviceTicketPool insufficient");
      
        // Commit TX
        _treasury.remainingTicketBalance[_t.tokenID] -= valueCredited;
        _treasury.serviceProviderAccount[_t.serviceProvider].serviceTicketPool -= valueCredited;
        _treasury._totalTicketPool -= valueCredited;


        _treasury.serviceProviderAccount[_t.serviceProvider].serviceProviderPool += valueCredited;
        _t.credits -= credits;
        _treasury._ticketData[_t.tokenID] = _t;
        TransferHelper.safeApprove(ERC20Token,serviceProviderWallet, 
            _treasury.serviceProviderAccount[_t.serviceProvider].serviceProviderPool);
        TransferHelper.safeApprove(ERC20Token, _treasury.owner, 
            _treasury.transactionPool[_treasury.owner] +
            _treasury.serviceProviderAccount[_t.serviceProvider].serviceTicketPool);

        return(_t);
    }

    function presentCertificateRepurchase(Treasury storage _treasury, address sender,Ticket memory _t) 
        internal 
        returns(Ticket memory)
    {
        uint256 refundValue = _t.certValue;
        address serviceProviderContract = _t.serviceProvider;
        address serviceProviderWallet = getServiceProviderWallet(_treasury, _t.serviceProvider);
        uint256 availableFunds = getServiceProviderPoolSize(_treasury, _t.serviceProvider);
        uint256 availableAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), serviceProviderWallet);
        uint256 serviceProviderWalletFunds = IERC20(_treasury.ERC20_Token).balanceOf(serviceProviderWallet);

        /**** START Verification */
        string memory _msg = "ServiceProvider contract ";
        string memory id = Strings.toString(
            uint256(uint160(serviceProviderContract))
        );
        if ( ! ((availableFunds + serviceProviderWalletFunds) >= refundValue) ) {
            _msg = string(abi.encodePacked(_msg, id, " and wallet "));
            id = Strings.toString(uint256(uint160(serviceProviderWallet)));
            _msg = string(
                abi.encodePacked(_msg, id, " have insufficient availableFunds=")
            );
            id = Strings.toString(availableFunds);
            _msg = string(abi.encodePacked(_msg, id, "/availableAllowance="));
            id = Strings.toString(availableAllowance);
            _msg = string(abi.encodePacked(_msg, id, "  plus insufficient availableWalletBalance= "));
            id = Strings.toString(serviceProviderWalletFunds);
            _msg = string(abi.encodePacked(_msg, id, " to refund certificate valued at "));
            id = Strings.toString(_t.certValue);
            _msg = string(abi.encodePacked(_msg, id, " .1"));
            require( (availableFunds + serviceProviderWalletFunds) >= refundValue, _msg);
        }
        /**** END Verification  */

        /**********
         *
         * if allowance for service provider covers the cost of refunding
         * we transfer from our treasury and reduce the allowance of the serviceProvider
         *
         **********/
        if (refundValue <= availableFunds) {
            _treasury.serviceProviderAccount[_t.serviceProvider].serviceProviderPool -= refundValue;
            TransferHelper.safeTransferFrom(_treasury.ERC20_Token,_treasury.owner,sender,refundValue);
            // reduce allowance for Service Provider
        } else if (refundValue <= (availableFunds + serviceProviderWalletFunds) ) {
            uint256 gap = refundValue - availableFunds;
            // first empty local balance
            _treasury.serviceProviderAccount[_t.serviceProvider].serviceProviderPool -= availableFunds;
            TransferHelper.safeTransferFrom(_treasury.ERC20_Token, _treasury.owner, sender, availableFunds);
            // then use remote wallet allowance
            TransferHelper.safeTransferFrom(_treasury.ERC20_Token, serviceProviderWallet, sender, gap);

            // TODO emit Event
        }
        _t.credits = 0;
        setTicketData(_treasury, _t.tokenID, _t);
        TransferHelper.safeApprove(_treasury.ERC20_Token, serviceProviderWallet,
            _treasury.serviceProviderAccount[_t.serviceProvider].serviceProviderPool);

        return(_t);
    }

 
    function verifyAllowances(Treasury storage _treasury, Ticket memory _t, uint256 totalAmount, uint256 serviceFee, uint256 resellerFee, uint256 transactionFee) 
        internal  
        view
    {
        uint256 nfticketAllowance;
        uint256 resellerAllowance;
        uint256 serviceProviderAllowance;
        uint256 contractBalance;

        // TODO this is only for one SP and one Reseller
        // so need to identify SP:reseller pair with a unique identifier and
        // keep separate accounts for each such pair

        contractBalance = IERC20(_treasury.ERC20_Token).balanceOf(_treasury.owner);
        address resellerWallet = getResellerWallet(_treasury, _t.serviceProvider);
        address serviceProviderWallet = getServiceProviderWallet(_treasury, _t.serviceProvider);
        
        nfticketAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), _treasury.owner);
        resellerAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), resellerWallet);
        serviceProviderAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), serviceProviderWallet);

    
        
        /*
        string memory _msg;
        if ( !( nfticketAllowance + resellerAllowance + serviceProviderAllowance <= contractBalance )) {
            _msg = "Contract balance ";
            _msg = string(abi.encodePacked(_msg, abi.encodePacked(Strings.toString(contractBalance)),
                    " is insufficient for (nfticketAllowance = "));
            _msg = string(abi.encodePacked(_msg, abi.encodePacked(Strings.toString(nfticketAllowance)),
                    ") + (resellerAllowance = "));
            _msg = string(abi.encodePacked(_msg, abi.encodePacked(Strings.toString(resellerAllowance)),
                    ")"));
        */
            require(nfticketAllowance + resellerAllowance + serviceProviderAllowance <= contractBalance,"VerifyAllowances: balance insufficient");
        /* } */
        // sum of absolute fees are equal to full ticket price
        require((serviceFee + resellerFee + transactionFee) == totalAmount, "Absolute fees do not add up.");
        // sum of relative fees are equal to ratioBase
        /*
        if ((_t.serviceFee + _t.resellerFee + _t.transactionFee).div(1 ether) != _treasury.ratioBASE) {
            _msg = "Relative fees do not add up. serviceFee = ";
            uint256 v = (_t.serviceFee + _t.resellerFee + _t.transactionFee).div(1 ether);
            _msg = string(abi.encodePacked(_msg, "fees =",Strings.toString(v), " ratioBASE=",Strings.toString(_treasury.ratioBASE)));
        */
            require( ((_t.serviceFee + _t.resellerFee + _t.transactionFee).div(1 ether)) == _treasury.ratioBASE,"VerifyAllowances: fees dont add up");
        /* } */

    }

    function isRegisteredServiceProvider(
        Treasury storage _treasury,
        address serviceProvider
    ) public view returns (bool) {
        return (_treasury._companyDescriptors[serviceProvider] != 0);
    }

    function registerServiceProvider(
        Treasury storage _treasury,
        address serviceProvider,
        uint32 companyDescriptor,
        address serviceProviderWallet
    ) internal returns (uint16 status) {
        if (isRegisteredServiceProvider(_treasury, serviceProvider)) {
            // this provider is already registered
            // TODO CRUD?
            require(false, "serviceProvider is already registered");
        } else {
            // register self as counterparty both as reseller as well as serviceProvider
            // this means this is a serviceProvider without a reseller
            _treasury._providers[companyDescriptor] = serviceProvider;
            _treasury._companyDescriptors[serviceProvider] = companyDescriptor;
            _treasury.serviceProvidersReseller[serviceProvider] = serviceProvider;
            _treasury.resellersServiceProvider[serviceProvider] = serviceProvider;
            _treasury.serviceProviderAccount[serviceProvider].serviceProviderWallet = serviceProviderWallet;
            _treasury.serviceProviderAccount[serviceProvider].resellerWallet = serviceProviderWallet;
        }
        return (200);
    }

    function getCompanyDescriptor(
        Treasury storage _treasury,
        address serviceProvider
    ) public view returns (uint32 descriptor) {
        return _treasury._companyDescriptors[serviceProvider];
    }

    function registerServiceReseller(
        Treasury storage _treasury,
        address serviceProvider,
        address reseller,
        address _resellerWallet
    ) internal returns (uint16 status) {

        _treasury.serviceProvidersReseller[serviceProvider] = reseller;
        _treasury.resellersServiceProvider[reseller] =  serviceProvider;
        _treasury.serviceProviderAccount[serviceProvider].resellerWallet = _resellerWallet;
        _treasury.serviceProviderAccount[serviceProvider].resellerPool = 0;

        return (200);
    }

    function storeCash(
        Treasury storage _t,
        address payable _owner,
        uint256 value
    ) public {
        _t.transactionPool[_owner] += value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// First byte is Processing Mode: from here we derive the caluclation and account booking logic
// basic differentiator being Ticket or Certificate (of ownership)
// all tickets need lowest bit of first semi-byte set
// all certificates need lowest bit of first semi-byte set
// all checkin-checkout tickets need second-lowest bit of first-semi-byte set --> 0x03000000
// high bits for each byte or half.byte are categories, low bits are instances
uint32 constant IS_CERTIFICATE =    0x40000000; // 2nd highest bit of CERTT-half-byte = 1 - cannot use highest bit?
uint32 constant IS_TICKET =         0x08000000; // highest bit of ticket-halfbyte = 1
uint32 constant CHECKOUT_TICKET =   0x09000000; // highest bit of ticket-halfbyte = 1 AND lowest bit = 1
uint32 constant CASH_VOUCHER =      0x0A000000; // highest bit of ticket-halfbyte = 1 AND 2nd bit = 1

// company identifiers last 10 bbits, e.g. 1023 companies
uint32 constant BLOXMOVE =          0x00000200; // top of 10 bits for company identifiers
uint32 constant NRVERSE =           0x00000001;
uint32 constant MITTWEIDA =         0x00000002;
uint32 constant EQUOTA =            0x00000003;

// Industrial Category - byte2
uint32 constant THG =               0x80800000; //  CERTIFICATE & highest bit of category half-byte = 1
uint32 constant REC =               0x80400000; //  CERTIFICATE & 2nd highest bit of category half-byte = 1

// Last byte is company identifier 1-255
uint32 constant NRVERSE_REC =       0x80800001; // CERTIFICATE & REC & 0x00000001
uint32 constant eQUOTA_THG =        0x80400003; // CERTIFICATE & THG & 0x00000003
uint32 constant MITTWEIDA_M4A =     0x09000002; // CHECKOUT_TICKET & MITTWEIDA
uint32 constant BLOXMOVE_CO =       0x09000200;
uint32 constant BLOXMOVE_CV =       0x0A000200;
uint32 constant BLOXMOVE_CI =       0x08000200;
uint32 constant BLOXMOVE_NG =       0x09000201;
uint32 constant DutchMaaS =         0x09000003;
uint32 constant TIER_MW =           0x09000004;



/***********************************************
 *
 * generic schematizable data payload
 * allows for customization between reseller and
 * service operator while keeping NFTicket agnostic
 *
 ***********************************************/

enum eDataType {
    _UNDEF,
    _UINT,
    _UINT256,
    _USTRING
}

struct TicketInfo {
    uint256 ticketFee;
    bool ticketUsed;
}


/*
* TODO reconcile redundancies between Payload, BuyNFTicketParams and Ticket
*/
struct Ticket {
    uint256 tokenID;
    address serviceProvider; // the index to the map where we keep info about serviceProviders
    uint32  serviceDescriptor;
    address issuedTo;
    uint256 certValue;
    uint    certValidFrom; // value can be redeemedn after this time
    uint256 price;
    uint256 credits;        // [7]
    uint256 pricePerCredit;
    uint256 serviceFee;
    uint256 resellerFee;
    uint256 transactionFee;
    string tokenURI;
}

struct Payload {
    address recipient;
    string tokenURI;
    DataSchema schema;
    string[] data;
    string[] serializedTicket;  
    uint256 certValue;
    string uuid;
    uint256 credits;
    uint256 pricePerCredit;
    uint256 price;
    uint256 timestamp;
}

/**** END TODO reconcile */

struct DataSchema {
    string name;
    uint32 size;
    string[] keys;
    uint8[] keyTypes;
}

struct DataRecords {
    DataSchema _schema;
    string[] _data; // a one-dimensional array of length [_schema.size * <number of records> ]
}

struct ConsumedRecord {
    uint certId;
    string energyType;
    string location;
    uint amount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: NATIVE_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
interface IERC165 {
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