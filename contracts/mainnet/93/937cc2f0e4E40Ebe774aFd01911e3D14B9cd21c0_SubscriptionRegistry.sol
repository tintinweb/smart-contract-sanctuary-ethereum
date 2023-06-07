// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) Team. Subscription Registry Contract V2
pragma solidity 0.8.19;

import "Ownable.sol";
import "SafeERC20.sol";
import "ITrustedWrapper.sol";
import "LibEnvelopTypes.sol";
import "ISubscriptionRegistry.sol";

/// The subscription platform operates with the following role model 
/// (it is assumed that the actor with the role is implemented as a contract).
/// `Service Provider` is a contract whose services are sold by subscription.
/// `Agent` - a contract that sells a subscription on behalf ofservice provider. 
///  May receive sales commission
///  `Platform` - SubscriptionRegistry contract that performs processingsubscriptions, 
///  fares, tickets

    struct SubscriptionType {
        uint256 timelockPeriod;    // in seconds e.g. 3600*24*30*12 = 31104000 = 1 year
        uint256 ticketValidPeriod; // in seconds e.g. 3600*24*30    =  2592000 = 1 month
        uint256 counter;     // For case when ticket valid for N usage, e.g. for Min N NFTs          
        bool isAvailable;    // USe for stop using tariff because we can`t remove tariff from array 
        address beneficiary; // Who will receive payment for tickets
    }
    struct PayOption {
        address paymentToken;   // token contract address or zero address for native token(ETC etc)
        uint256 paymentAmount;  // ticket price exclude any fees
        uint16 agentFeePercent; // 100%-10000, 20%-2000, 3%-300 
    }

    struct Tariff {
        SubscriptionType subscription; // link to subscriptionType
        PayOption[] payWith; // payment option array. Use it for price in defferent tokens
    }

    // native subscribtionManager tickets format
    struct Ticket {
        uint256 validUntil; // Unixdate, tickets not valid after
        uint256 countsLeft; // for tarif with fixed use counter
    }

/// @title Base contract in Envelop Subscription Platform 
/// @author Envelop Team
/// @notice You can use this contract for make and operate any on-chain subscriptions
/// @dev  Contract that performs processing subscriptions, fares(tariffs), tickets
/// @custom:please see example folder.
contract SubscriptionRegistry is Ownable {
    using SafeERC20 for IERC20;

    uint256 constant public PERCENT_DENOMINATOR = 10000;

    /// @notice Envelop Multisig contract
    address public platformOwner; 
    
    /// @notice Platform owner can receive fee from each payments
    uint16 public platformFeePercent = 50; // 100%-10000, 20%-2000, 3%-300


    /// @notice address used for wrapp & lock incoming assets
    address  public mainWrapper; 
    /// @notice Used in case upgrade this contract
    address  public previousRegistry; 
    /// @notice Used in case upgrade this contract
    address  public proxyRegistry; 

    /// @notice Only white listed assets can be used on platform
    mapping(address => bool) public whiteListedForPayments;
    
    /// @notice from service(=smart contract address) to tarifs
    mapping(address => Tariff[]) public availableTariffs;

    /// @notice from service to agent to available tarifs(tarif index);
    mapping(address => mapping(address => uint256[])) public agentServiceRegistry;
     
    
    /// @notice mapping from user addres to service contract address  to ticket
    mapping(address => mapping(address => Ticket)) public userTickets;

    event PlatfromFeeChanged(uint16 indexed newPercent);
    event WhitelistPaymentTokenChanged(address indexed asset, bool indexed state);
    event TariffChanged(address indexed service, uint256 indexed tariffIndex);
    event TicketIssued(
        address indexed service, 
        address indexed agent, 
        address indexed forUser, 
        uint256 tariffIndex
    );

    constructor(address _platformOwner) {
        require(_platformOwner != address(0),'Zero platform fee receiver');
        platformOwner = _platformOwner;
    } 
   
    /**
     * @notice Add new tariff for caller
     * @dev Call this method from ServiceProvider
     * for setup new tariff 
     * using `Tariff` data type(please see above)
     *
     * @param _newTariff full encded Tariff object
     * @return last added tariff index in  Tariff[] array 
     * for current Service Provider (msg.sender)
     */
    function registerServiceTariff(Tariff calldata _newTariff) 
        external 
        returns(uint256)
    {
        // TODO
        // Tarif structure check
        // PayWith array whiteList check
        return _addTariff(msg.sender, _newTariff);
    }

    /**
     * @notice Edit tariff for caller
     * @dev Call this method from ServiceProvider
     * for setup new tariff 
     * using `Tariff` data type(please see above)
     *
     * @param _tariffIndex  - index in `availableTariffs` array 
     * @param _timelockPeriod - see SubscriptionType notice above
     * @param _ticketValidPeriod - see SubscriptionType notice above
     * @param _counter - see SubscriptionType notice above
     * @param _isAvailable - see SubscriptionType notice above
     * @param _beneficiary - see SubscriptionType notice above
     */
    function editServiceTariff(
        uint256 _tariffIndex, 
        uint256 _timelockPeriod,
        uint256 _ticketValidPeriod,
        uint256 _counter,
        bool _isAvailable,
        address _beneficiary
    ) 
        external
    {
        // TODO
        // Tariff structure check
        // PayWith array whiteList check
        _editTariff(
            msg.sender,
            _tariffIndex, 
            _timelockPeriod,
            _ticketValidPeriod,
            _counter,
            _isAvailable,
            _beneficiary
        );

    }

    
    /**
     * @notice Add tariff PayOption for exact service
     * @dev Call this method from ServiceProvider
     * for add tariff PayOption 
     *
     * @param _tariffIndex  - index in `availableTariffs` array 
     * @param _paymentToken - see PayOption notice above
     * @param _paymentAmount - see PayOption notice above
     * @param _agentFeePercent - see PayOption notice above
     * @return last added PaymentOption index in array 
     * for _tariffIndex Tariff of caller Service Provider (msg.sender)
     */
    function addTariffPayOption(
        uint256 _tariffIndex,
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external returns(uint256)
    {
        return _addTariffPayOption(
            msg.sender,
            _tariffIndex,
            _paymentToken,
            _paymentAmount,
            _agentFeePercent
        );
    }

    /**
     * @notice Edit tariff PayOption for exact service
     * @dev Call this method from ServiceProvider
     * for edit tariff PayOption 
     *
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @param _paymentToken - see PayOption notice above
     * @param _paymentAmount - see PayOption notice above
     * @param _agentFeePercent - see PayOption notice above
     * for _tariffIndex Tariff of caller Service Provider (msg.sender)
     */
    function editTariffPayOption(
        uint256 _tariffIndex,
        uint256 _payWithIndex, 
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external 
    {
        _editTariffPayOption(
            msg.sender,
            _tariffIndex,
            _payWithIndex, 
            _paymentToken,
            _paymentAmount,
            _agentFeePercent
        );
    }

    /**
     * @notice Authorize agent for caller service provider
     * @dev Call this method from ServiceProvider
     *
     * @param _agent  - address of contract that implement Agent role 
     * @param _serviceTariffIndexes  - array of index in `availableTariffs` array
     * that available for given `_agent` 
     * @return full array of actual tarifs for this agent 
     */
    function authorizeAgentForService(
        address _agent,
        uint256[] calldata _serviceTariffIndexes
    ) external virtual returns (uint256[] memory) 
    {
        // remove previouse tariffs
        delete agentServiceRegistry[msg.sender][_agent];
        uint256[] storage currentServiceTariffsOfAgent = agentServiceRegistry[msg.sender][_agent];
        // check that adding tariffs still available
        for(uint256 i; i < _serviceTariffIndexes.length; ++ i) {
            if (availableTariffs[msg.sender][_serviceTariffIndexes[i]].subscription.isAvailable){
                currentServiceTariffsOfAgent.push(_serviceTariffIndexes[i]);
            }
        }
        return currentServiceTariffsOfAgent;
    }
    
     /**
     * @notice By Ticket for subscription
     * @dev Call this method from Agent
     *
     * @param _service  - Service Provider address 
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @param _buyFor - address for whome this ticket would be bought 
     * @param _payer - address of payer for this ticket
     * @return ticket structure that would be use for validate service process
     */
    function buySubscription(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex,
        address _buyFor,
        address _payer
    ) external 
      payable
      returns(Ticket memory ticket) {
        // Cant buy ticket for nobody
        require(_buyFor != address(0),'Cant buy ticket for nobody');

        require(
            availableTariffs[_service][_tariffIndex].subscription.isAvailable,
            'This subscription not available'
        );

        // Not used in this implementation
        // require(
        //     availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount > 0,
        //     'This Payment option not available'
        // );

        // Check that agent is authorized for purchace of this service
        require(
            _isAgentAuthorized(msg.sender, _service, _tariffIndex), 
            'Agent not authorized for this service tariff' 
        );
        
        (bool isValid, bool needFix) = _isTicketValid(_buyFor, _service);
        require(!isValid, 'Only one valid ticket at time');

        //lets safe user ticket (only one ticket available in this version)
        ticket = Ticket(
            availableTariffs[_service][_tariffIndex].subscription.ticketValidPeriod + block.timestamp,
            availableTariffs[_service][_tariffIndex].subscription.counter
        );
        userTickets[_buyFor][_service] = ticket;

        // Lets receive payment tokens FROM sender
        if (availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount > 0){
            _processPayment(_service, _tariffIndex, _payWithIndex, _payer);
        }
        emit TicketIssued(_service, msg.sender, _buyFor, _tariffIndex);
    }

    /**
     * @notice Check that `_user` have still valid ticket for this service.
     * Decrement ticket counter in case it > 0
     * @dev Call this method from ServiceProvider
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @return ok True in case ticket is valid
     */
    function checkAndFixUserSubscription(
        address _user
    ) external returns (bool ok){
        
        address _service = msg.sender;
        // Check user ticket
        (bool isValid, bool needFix) = _isTicketValid(_user, msg.sender);
        
        // Proxy to previos
        if (!isValid && previousRegistry != address(0)) {
            (isValid, needFix) = ISubscriptionRegistry(previousRegistry).checkUserSubscription(
                _user, 
                _service
            );
            // Case when valid ticket stored in previousManager
            if (isValid ) {
                if (needFix){
                    ISubscriptionRegistry(previousRegistry).fixUserSubscription(
                        _user, 
                        _service
                    );
                }
                ok = true;
                return ok;
            }
        }
        require(isValid,'Valid ticket not found');
        
        // Fix action (for subscription with counter)
        if (needFix){
            _fixUserSubscription(_user, msg.sender);    
        }
                
        ok = true;
    }

     /**
     * @notice Decrement ticket counter in case it > 0
     * @dev Call this method from new SubscriptionRegistry in case of upgrade
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _serviceFromProxy  - address of service from more new SubscriptionRegistry contract 
     */
    function fixUserSubscription(
        address _user,
        address _serviceFromProxy
    ) public {
        require(proxyRegistry !=address(0) && msg.sender == proxyRegistry,
            'Only for future registry'
        );
        _fixUserSubscription(_user, _serviceFromProxy);
    }

    ////////////////////////////////////////////////////////////////
    
    /**
     * @notice Check that `_user` have still valid ticket for this service.
     * @dev Call this method from any context
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _service - address of Service Provider
     * @return ok True in case ticket is valid
     * @return needFix True in case ticket has counter > 0
     */
    function checkUserSubscription(
        address _user, 
        address _service
    ) external view returns (bool ok, bool needFix) {
        (ok, needFix)  = _isTicketValid(_user, _service);
        if (!ok && previousRegistry != address(0)) {
            (ok, needFix) = ISubscriptionRegistry(previousRegistry).checkUserSubscription(
                _user, 
                _service
            );
        }
    }

    /**
     * @notice Returns `_user` ticket for this service.
     * @dev Call this method from any context
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _service - address of Service Provider
     * @return ticket
     */
    function getUserTicketForService(
        address _service,
        address _user
    ) public view returns(Ticket memory) 
    {
        return userTickets[_user][_service];
    }

    /**
     * @notice Returns array of Tariff for `_service`
     * @dev Call this method from any context
     *
     * @param _service - address of Service Provider
     * @return Tariff array
     */
    function getTariffsForService(address _service) external view returns (Tariff[] memory) {
        return availableTariffs[_service];
    }

    /**
     * @notice Returns ticket price include any fees
     * @dev Call this method from any context
     *
     * @param _service - address of Service Provider
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @return tulpe with payment token an ticket price 
     */
    function getTicketPrice(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex
    ) public view virtual returns (address, uint256) 
    {
        if (availableTariffs[_service][_tariffIndex].subscription.timelockPeriod != 0)
        {
            return(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );
        } else {
            return(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                + availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                    *availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].agentFeePercent
                    /PERCENT_DENOMINATOR
                + availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                        *_platformFeePercent(_service, _tariffIndex, _payWithIndex) 
                        /PERCENT_DENOMINATOR
            );
        }
    }

    /**
     * @notice Returns array of Tariff for `_service` assigned to `_agent`
     * @dev Call this method from any context
     *
     * @param _agent - address of Agent
     * @param _service - address of Service Provider
     * @return tuple with two arrays: indexes and Tariffs
     */
    function getAvailableAgentsTariffForService(
        address _agent, 
        address _service
    ) external view virtual returns(uint256[] memory, Tariff[] memory) 
    {
        //First need get count of tarifs that still available
        uint256 availableCount;
        for (uint256 i; i < agentServiceRegistry[_service][_agent].length; ++i){
            if (availableTariffs[_service][
                  agentServiceRegistry[_service][_agent][i]
                ].subscription.isAvailable
            ) {++availableCount;}
        }
        
        Tariff[]  memory tariffs = new Tariff[](availableCount);
        uint256[] memory indexes = new uint256[](availableCount);
        for (uint256 i; i < agentServiceRegistry[_service][_agent].length; ++i){
            if (availableTariffs[_service][
                  agentServiceRegistry[_service][_agent][i]
                ].subscription.isAvailable
            ) 
            {
                tariffs[availableCount - 1] = availableTariffs[_service][
                  agentServiceRegistry[_service][_agent][i]
                ];
                indexes[availableCount - 1] = agentServiceRegistry[_service][_agent][i];
                --availableCount;
            }
        }
        return (indexes, tariffs);
    }    
    ////////////////////////////////////////////////////////////////
    //////////     Admins                                     //////
    ////////////////////////////////////////////////////////////////

    function setAssetForPaymentState(address _asset, bool _isEnable)
        external onlyOwner 
    {
        whiteListedForPayments[_asset] = _isEnable;
        emit WhitelistPaymentTokenChanged(_asset, _isEnable);
    }

    function setMainWrapper(address _wrapper) external onlyOwner {
        mainWrapper = _wrapper;
    }

    function setPlatformOwner(address _newOwner) external {
        require(msg.sender == platformOwner, 'Only platform owner');
        require(_newOwner != address(0),'Zero platform fee receiver');
        platformOwner = _newOwner;
    }

    function setPlatformFeePercent(uint16 _newPercent) external {
        require(msg.sender == platformOwner, 'Only platform owner');
        platformFeePercent = _newPercent;
        emit PlatfromFeeChanged(platformFeePercent);
    }

    

    function setPreviousRegistry(address _registry) external onlyOwner {
        previousRegistry = _registry;
    }

    function setProxyRegistry(address _registry) external onlyOwner {
        proxyRegistry = _registry;
    }
    /////////////////////////////////////////////////////////////////////
    
    function _processPayment(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex,
        address _payer
    ) 
        internal 
        virtual 
        returns(bool)
    {
        // there are two payment method for this implementation.
        // 1. with wrap and lock in asset (no fees)
        // 2. simple payment (agent & platform fee enabled)
        if (availableTariffs[_service][_tariffIndex].subscription.timelockPeriod != 0){
            require(msg.value == 0, 'Ether Not accepted in this method');
            // 1. with wrap and lock in asset
            IERC20(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
            ).safeTransferFrom(
                _payer, 
                address(this),
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );

            // Lets approve received for wrap 
            IERC20(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
            ).safeApprove(
                mainWrapper,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );

            // Lets wrap with timelock and appropriate params
            ETypes.INData memory _inData;
            ETypes.AssetItem[] memory _collateralERC20 = new ETypes.AssetItem[](1);
            ETypes.Lock[] memory timeLock =  new ETypes.Lock[](1);
            // Only need set timelock for this wNFT
            timeLock[0] = ETypes.Lock(
                0x00, // timelock
                availableTariffs[_service][_tariffIndex].subscription.timelockPeriod + block.timestamp
            ); 
            _inData = ETypes.INData(
                ETypes.AssetItem(
                    ETypes.Asset(ETypes.AssetType.EMPTY, address(0)),
                    0,0
                ),          // INAsset
                address(0), // Unwrap destinition    
                new ETypes.Fee[](0), // Fees
                //new ETypes.Lock[](0), // Locks
                timeLock,
                new ETypes.Royalty[](0), // Royalties
                ETypes.AssetType.ERC721, // Out type
                0, // Out Balance
                0x0000 // Rules
            );

            _collateralERC20[0] = ETypes.AssetItem(
                ETypes.Asset(
                    ETypes.AssetType.ERC20,
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                ),
                0,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );
            
            ITrustedWrapper(mainWrapper).wrap(
                _inData,
                _collateralERC20,
                _payer
            );

        } else {
            // 2. simple payment
            if (availableTariffs[_service][_tariffIndex]
                .payWith[_payWithIndex]
                .paymentToken != address(0)
            ) 
            {
                // pay with erc20 
                require(msg.value == 0, 'Ether Not accepted in this method');
                // 2.1. Body payment  
                IERC20(
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                ).safeTransferFrom(
                    _payer, 
                    availableTariffs[_service][_tariffIndex].subscription.beneficiary,
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                );

                // 2.2. Agent fee payment
                IERC20(
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                ).safeTransferFrom(
                    _payer, 
                    msg.sender,
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                     *availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].agentFeePercent
                     /PERCENT_DENOMINATOR
                );

                // 2.3. Platform fee 
                uint256 _pFee = _platformFeePercent(_service, _tariffIndex, _payWithIndex); 
                if (_pFee > 0) {
                    IERC20(
                        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                    ).safeTransferFrom(
                        _payer, 
                        platformOwner, //
                        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                          *_pFee
                          /PERCENT_DENOMINATOR
                    );
                }

            } else {
                // pay with native token(eth, bnb, etc)
                (, uint256 needPay) = getTicketPrice(_service, _tariffIndex,_payWithIndex);
                require(msg.value >= needPay, 'Not enough ether');
                // 2.4. Body ether payment
                sendValue(
                    payable(availableTariffs[_service][_tariffIndex].subscription.beneficiary),
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                );

                // 2.5. Agent fee payment
                sendValue(
                    payable(msg.sender),
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                      *availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].agentFeePercent
                      /PERCENT_DENOMINATOR
                );

                // 2.3. Platform fee 
                uint256 _pFee = _platformFeePercent(_service, _tariffIndex, _payWithIndex); 
                if (_pFee > 0) {

                    sendValue(
                        payable(platformOwner),
                        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                          *_pFee
                          /PERCENT_DENOMINATOR
                    );
                }
                // return change
                if  ((msg.value - needPay) > 0) {
                    address payable s = payable(_payer);
                    s.transfer(msg.value - needPay);
                }
            }
        }
    }

    // In this impementation params not used. 
    // Can be ovveriden in other cases
    function _platformFeePercent(
        address _service, 
        uint256 _tariffIndex, 
        uint256  _payWithIndex
    ) internal view virtual returns(uint256) 
    {
        return platformFeePercent;
    }

    function _addTariff(address _service, Tariff calldata _newTariff) 
        internal returns(uint256) 
    {
        require (_newTariff.payWith.length > 0, 'No payment method');
        for (uint256 i; i < _newTariff.payWith.length; ++i){
            require(
                whiteListedForPayments[_newTariff.payWith[i].paymentToken],
                'Not whitelisted for payments'
            );      
        }
        require(
            _newTariff.subscription.ticketValidPeriod > 0 
            || _newTariff.subscription.counter > 0,
            'Tariff has no valid ticket option'  
        );
        availableTariffs[_service].push(_newTariff);
        emit TariffChanged(_service, availableTariffs[_service].length - 1);
        return availableTariffs[_service].length - 1;
    }


    function _editTariff(
        address _service,
        uint256 _tariffIndex, 
        uint256 _timelockPeriod,
        uint256 _ticketValidPeriod,
        uint256 _counter,
        bool _isAvailable,
        address _beneficiary
    ) internal  
    {
        availableTariffs[_service][_tariffIndex].subscription.timelockPeriod    = _timelockPeriod;
        availableTariffs[_service][_tariffIndex].subscription.ticketValidPeriod = _ticketValidPeriod;
        availableTariffs[_service][_tariffIndex].subscription.counter = _counter;
        availableTariffs[_service][_tariffIndex].subscription.isAvailable = _isAvailable;    
        availableTariffs[_service][_tariffIndex].subscription.beneficiary = _beneficiary;    
        emit TariffChanged(_service, _tariffIndex);
    }
   
    function _addTariffPayOption(
        address _service,
        uint256 _tariffIndex,
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) internal returns(uint256)
    {
        require(whiteListedForPayments[_paymentToken], 'Not whitelisted for payments');
        availableTariffs[_service][_tariffIndex].payWith.push(
            PayOption(_paymentToken, _paymentAmount, _agentFeePercent)
        ); 
        emit TariffChanged(_service, _tariffIndex);
        return availableTariffs[_service][_tariffIndex].payWith.length - 1;
    }

    function _editTariffPayOption(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex, 
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) internal  
    {
        require(whiteListedForPayments[_paymentToken], 'Not whitelisted for payments');
        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex] 
        = PayOption(_paymentToken, _paymentAmount, _agentFeePercent);  
        emit TariffChanged(_service, _tariffIndex);  
    }

    function _fixUserSubscription(
        address _user,
        address _service
    ) internal {
       
        // Fix action (for subscription with counter)
        if (userTickets[_user][_service].countsLeft > 0) {
            -- userTickets[_user][_service].countsLeft; 
        }
    }

        
   function _isTicketValid(address _user, address _service) 
        internal 
        view 
        returns (bool isValid, bool needFix ) 
    {
        isValid =  userTickets[_user][_service].validUntil > block.timestamp 
            || userTickets[_user][_service].countsLeft > 0;
        needFix =  userTickets[_user][_service].countsLeft > 0;   
    }

    function _isAgentAuthorized(
        address _agent, 
        address _service, 
        uint256 _tariffIndex
    ) 
        internal
        view
        returns(bool authorized)
    {
        for (uint256 i; i < agentServiceRegistry[_service][_agent].length; ++ i){
            if (agentServiceRegistry[_service][_agent][i] == _tariffIndex){
                authorized = true;
                return authorized;
            }
        }
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "IWrapper.sol";

interface ITrustedWrapper is IWrapper  {

    function trustedOperator() external view returns(address);    
    
    function wrapUnsafe(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external
        payable
        returns (ETypes.AssetItem memory); 

    function transferIn(
        ETypes.AssetItem memory _assetItem,
        address _from
    ) 
        external
        payable  
    returns (uint256 _transferedValue);
   
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";

interface IWrapper  {

    event WrappedV1(
        address indexed inAssetAddress,
        address indexed outAssetAddress, 
        uint256 indexed inAssetTokenId, 
        uint256 outTokenId,
        address wnftFirstOwner,
        uint256 nativeCollateralAmount,
        bytes2  rules
    );

    event UnWrappedV1(
        address indexed wrappedAddress,
        address indexed originalAddress,
        uint256 indexed wrappedId, 
        uint256 originalTokenId, 
        address beneficiary, 
        uint256 nativeCollateralAmount,
        bytes2  rules 
    );

    event CollateralAdded(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint8   assetType,
        address collateralAddress,
        uint256 collateralTokenId,
        uint256 collateralBalance
    );

    event PartialUnWrapp(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint256 lastCollateralIndex
    );
    event SuspiciousFail(
        address indexed wrappedAddress,
        uint256 indexed wrappedId, 
        address indexed failedContractAddress
    );

    event EnvelopFee(
        address indexed receiver,
        address indexed wNFTConatract,
        uint256 indexed wNFTTokenId,
        uint256 amount
    );

    function wrap(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external 
        payable 
    returns (ETypes.AssetItem memory);

    // function wrapUnsafe(
    //     ETypes.INData calldata _inData, 
    //     ETypes.AssetItem[] calldata _collateral, 
    //     address _wrappFor
    // ) 
    //     external 
    //     payable
    // returns (ETypes.AssetItem memory);

    function addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) external payable;

    // function addCollateralUnsafe(
    //     address _wNFTAddress, 
    //     uint256 _wNFTTokenId, 
    //     ETypes.AssetItem[] calldata _collateral
    // ) 
    //     external 
    //     payable;

    function unWrap(
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) external; 

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) external; 

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        bool _isEmergency
    ) external;

    function chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        external  
        returns (bool);   

    ////////////////////////////////////////////////////////////////////// 
    
    function MAX_COLLATERAL_SLOTS() external view returns (uint256);
    function protocolTechToken() external view returns (address);
    function protocolWhiteList() external view returns (address);
    //function trustedOperators(address _operator) external view returns (bool); 
    //function lastWNFTId(ETypes.AssetType _assetType) external view returns (ETypes.NFTItem); 

    function getWrappedToken(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns (ETypes.WNFT memory);

    function getOriginalURI(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns(string memory); 
    
    function getCollateralBalanceAndIndex(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        ETypes.AssetType _collateralType, 
        address _erc,
        uint256 _tokenId
    ) external view returns (uint256, uint256);
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.19;

/// @title Flibrary ETypes in Envelop PrtocolV1 
/// @author Envelop Team
/// @notice This contract implement main protocol's data types
library ETypes {

    enum AssetType {EMPTY, NATIVE, ERC20, ERC721, ERC1155, FUTURE1, FUTURE2, FUTURE3}
    
    struct Asset {
        AssetType assetType;
        address contractAddress;
    }

    struct AssetItem {
        Asset asset;
        uint256 tokenId;
        uint256 amount;
    }

    struct NFTItem {
        address contractAddress;
        uint256 tokenId;   
    }

    struct Fee {
        bytes1 feeType;
        uint256 param;
        address token; 
    }

    struct Lock {
        bytes1 lockType;
        uint256 param; 
    }

    struct Royalty {
        address beneficiary;
        uint16 percent;
    }

    struct WNFT {
        AssetItem inAsset;
        AssetItem[] collateral;
        address unWrapDestination;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        bytes2 rules;

    }

    struct INData {
        AssetItem inAsset;
        address unWrapDestination;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        AssetType outType;
        uint256 outBalance;      //0- for 721 and any amount for 1155
        bytes2 rules;

    }

    struct WhiteListItem {
        bool enabledForFee;
        bool enabledForCollateral;
        bool enabledRemoveFromCollateral;
        address transferFeeModel;
    }

    struct Rules {
        bytes2 onlythis;
        bytes2 disabled;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SubscriptionType, PayOption, Tariff, Ticket} from "SubscriptionRegistry.sol";
interface ISubscriptionRegistry   {

    /**
     * @notice Add new tariff for caller
     * @dev Call this method from ServiceProvider
     * for setup new tariff 
     * using `Tariff` data type(please see above)
     *
     * @param _newTariff full encded Tariff object
     * @return last added tariff index in  Tariff[] array 
     * for current Service Provider (msg.sender)
     */
    function registerServiceTariff(Tariff calldata _newTariff) external returns(uint256);
    
    
    /**
     * @notice Authorize agent for caller service provider
     * @dev Call this method from ServiceProvider
     *
     * @param _agent  - address of contract that implement Agent role 
     * @param _serviceTariffIndexes  - array of index in `availableTariffs` array
     * that available for given `_agent` 
     * @return full array of actual tarifs for this agent 
     */
    function authorizeAgentForService(
        address _agent,
        uint256[] calldata _serviceTariffIndexes
    ) external returns (uint256[] memory);

    /**
     * @notice By Ticket for subscription
     * @dev Call this method from Agent
     *
     * @param _service  - Service Provider address 
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @param _buyFor - address for whome this ticket would be bought 
     * @param _payer - address of payer for this ticket
     * @return ticket structure that would be use for validate service process
     */ 
    function buySubscription(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex,
        address _buyFor,
        address _payer
    ) external payable returns(Ticket memory ticket);

    /**
     * @notice Edit tariff for caller
     * @dev Call this method from ServiceProvider
     * for setup new tariff 
     * using `Tariff` data type(please see above)
     *
     * @param _tariffIndex  - index in `availableTariffs` array 
     * @param _timelockPeriod - see SubscriptionType notice above
     * @param _ticketValidPeriod - see SubscriptionType notice above
     * @param _counter - see SubscriptionType notice above
     * @param _isAvailable - see SubscriptionType notice above
     * @param _beneficiary - see SubscriptionType notice above
     */
    function editServiceTariff(
        uint256 _tariffIndex, 
        uint256 _timelockPeriod,
        uint256 _ticketValidPeriod,
        uint256 _counter,
        bool _isAvailable,
        address _beneficiary
    ) external;

    /**
     * @notice Add tariff PayOption for exact service
     * @dev Call this method from ServiceProvider
     * for add tariff PayOption 
     *
     * @param _tariffIndex  - index in `availableTariffs` array 
     * @param _paymentToken - see PayOption notice above
     * @param _paymentAmount - see PayOption notice above
     * @param _agentFeePercent - see PayOption notice above
     * @return last added PaymentOption index in array 
     * for _tariffIndex Tariff of caller Service Provider (msg.sender)
     */
    function addTariffPayOption(
        uint256 _tariffIndex,
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external returns(uint256);
    
    /**
     * @notice Edit tariff PayOption for exact service
     * @dev Call this method from ServiceProvider
     * for edit tariff PayOption 
     *
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @param _paymentToken - see PayOption notice above
     * @param _paymentAmount - see PayOption notice above
     * @param _agentFeePercent - see PayOption notice above
     * for _tariffIndex Tariff of caller Service Provider (msg.sender)
     */
    function editTariffPayOption(
        uint256 _tariffIndex,
        uint256 _payWithIndex, 
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external; 
    
    /**
     * @notice Check that `_user` have still valid ticket for this service.
     * @dev Call this method from any context
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _service - address of Service Provider
     * @return ok True in case ticket is valid
     * @return needFix True in case ticket has counter > 0
     */
    function checkUserSubscription(
        address _user, 
        address _service
    ) external view returns (bool ok, bool needFix);


    /**
     * @notice Check that `_user` have still valid ticket for this service.
     * Decrement ticket counter in case it > 0
     * @dev Call this method from ServiceProvider
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @return ok True in case ticket is valid
     */
    function checkAndFixUserSubscription(address _user) external returns (bool ok);

    /**
     * @notice Decrement ticket counter in case it > 0
     * @dev Call this method from new SubscriptionRegistry in case of upgrade
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _serviceFromProxy  - address of service from more new SubscriptionRegistry contract 
     */
    function fixUserSubscription(address _user, address _serviceFromProxy) external;


    /**
     * @notice Returns `_user` ticket for this service.
     * @dev Call this method from any context
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _service - address of Service Provider
     * @return ticket
     */
    function getUserTicketForService(
        address _service,
        address _user
    ) external view returns(Ticket memory); 
    
    /**
     * @notice Returns array of Tariff for `_service`
     * @dev Call this method from any context
     *
     * @param _service - address of Service Provider
     * @return Tariff array
     */
    function getTariffsForService(address _service) external view returns (Tariff[] memory);

    /**
     * @notice Returns ticket price include any fees
     * @dev Call this method from any context
     *
     * @param _service - address of Service Provider
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @return tulpe with payment token an ticket price 
     */
    function getTicketPrice(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex
    ) external view returns (address, uint256);

    /**
     * @notice Returns array of Tariff for `_service` assigned to `_agent`
     * @dev Call this method from any context
     *
     * @param _agent - address of Agent
     * @param _service - address of Service Provider
     * @return Tariff array
     */
    function getAvailableAgentsTariffForService(
        address _agent, 
        address _service
    ) external view returns(Tariff[] memory); 
}