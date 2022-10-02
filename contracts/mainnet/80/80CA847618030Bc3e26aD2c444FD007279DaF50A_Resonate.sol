// SPDX-License-Identifier: GNU-GPL

pragma solidity >=0.8.0;

import "./interfaces/IERC4626.sol";
import "./interfaces/IRevest.sol";
import "./interfaces/IFNFTHandler.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IPriceProvider.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IResonate.sol";
import "./interfaces/ISmartWalletWhitelistV2.sol";

import "./interfaces/ISmartWallet.sol";
import "./interfaces/IPoolWallet.sol";
import "./interfaces/IResonateHelper.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";

/** @title Resonate
 * @author RobAnon
 * @author 0xTraub
 * @author 0xTinder
 */
contract Resonate is IResonate, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Bytes32AddressLib for address;
    using Bytes32Conversion for bytes32;

    ///
    /// Coefficients and Variable Declarations
    ///

    /// Precision for calculating rates
    uint private constant PRECISION = 1 ether;

    /// Denominator for fee calculations
    uint private constant DENOM = 100;

    /// Minimum deposit
    uint private constant MIN_DEPOSIT = 1E3;

    // uint32, address, address, address pack together to 64 bytes

    /// Minimum lockup period
    uint32 private constant MIN_LOCKUP = 1 days;

    /// The address to which fees are paid
    address private immutable DEV_ADDRESS;

    /// The Revest Address Registry
    address public immutable REGISTRY_ADDRESS;

    /// The OutputReceiver Proxy Address
    address public immutable PROXY_OUTPUT_RECEIVER;

    /// The fee numerator 
    uint32 private constant FEE = 5;

    /// The AddressLock Proxy Address
    address public immutable PROXY_ADDRESS_LOCK;

    /// The ResonateHelper address
    address public immutable override RESONATE_HELPER;

    /// The owner
    address public owner;

    /// Maps yield-farm address to adapter address
    mapping(address => address) public override vaultAdapters;

    /// Maps fnftIds to their relevant index
    mapping(uint => uint) public fnftIdToIndex;

    /// Contains all activated orders 
    mapping (uint => Active) public override activated;

    /// Mapping to residual interest for an interest-bearing FNFT
    mapping(uint => uint) public override residuals;

    /// Map poolIds to their respective configs
    mapping(bytes32 => PoolConfig) public override pools;

    /// Provider queue
    mapping(bytes32 => mapping(uint => Order)) public override providerQueue;

    /// Consumer queue
    mapping(bytes32 => mapping(uint => Order)) public override consumerQueue;

    /// Queue tracker mapping
    mapping(bytes32 => PoolQueue) public override queueMarkers;

    /// Maps contract address to assets it has approval to spend from this contract
    mapping (address => mapping (address => bool)) private _approvedContracts;

    /// The FNFTHandler address, immutable for increased decentralization
    IFNFTHandler private immutable FNFT_HANDLER;

    /// The SmartWalletWhitelist contract to control access
    ISmartWalletWhitelistV2 private immutable SMART_WALLET_WHITELIST;

    /// Oracle Tracker
    IPriceProvider private immutable PRICE_PROVIDER;

    /**
     * @notice the constructor for Resonate
     * @param _router the Revest AddressRegistry contract address
     * @param _proxyOutputReceiver the OutputReceiver proxy address to use for Resonate. 
     * @param _proxyAddressLock the AddressLock proxy address to use for Resonate. 
     * @param _resonateHelper the ResonateHelper address
     * @dev This should be called after the above three contracts have been deployed
     */
    constructor(
        address _router, 
        address _proxyOutputReceiver, 
        address _proxyAddressLock, 
        address _resonateHelper,
        address _smartWalletWhitelist,
        address _priceProvider,
        address _dev_address
    ) {
        require(
            _router != address(0) && 
            _proxyOutputReceiver != address(0) && 
            _proxyAddressLock != address(0) && 
            _resonateHelper != address(0) && 
            _smartWalletWhitelist != address(0) &&
            _priceProvider != address(0) &&
            _dev_address != address(0),
        'ER003');

        REGISTRY_ADDRESS = _router;

        PROXY_OUTPUT_RECEIVER = _proxyOutputReceiver;
        PROXY_ADDRESS_LOCK = _proxyAddressLock;
        RESONATE_HELPER = _resonateHelper;
        DEV_ADDRESS = _dev_address;
        FNFT_HANDLER = IFNFTHandler(IAddressRegistry(_router).getRevestFNFT());
        SMART_WALLET_WHITELIST = ISmartWalletWhitelistV2(_smartWalletWhitelist);
        PRICE_PROVIDER = IPriceProvider(_priceProvider);  

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "ER024");
        _;
    }

    ///
    /// Transactional Functions
    ///

    /** 
     * @notice Creates a pool, only if it does not already exist
     * @param asset The payment asset for this pool. An oracle must exist if it is different than vaultAsset
     * @param vault The Vault to use. Should be the raw vault, not the adapter. If 4626, use the 4626 here
     * @param rate The upfront payout rate, in 1E18 precision
     * @param additionalRate The amount to add to the upfront rate to get the expected interest if fixed-income. Zero otherwise
     * @param lockupPeriod The amount of time the principal will be locked for if fixed-term. Zero otherwise
     * @param packetSize The standardized size of a single packet. Often measured in thousandths of a token
     * @param poolName The name of the pool. Will not be stored, only needed for Frontend display
     * @return poolId The poolId that the above parameters result in
     * @dev Cross-asset pools have more pre-conditions than others. This function will not deposit anything and follow-up operations are needed
     */
    function createPool(
        address asset,
        address vault, 
        uint128 rate,
        uint128 additionalRate,
        uint32 lockupPeriod, 
        uint packetSize,
        string calldata poolName
    ) external nonReentrant returns (bytes32 poolId) {
        address vaultAsset;
        {
            address adapter = vaultAdapters[vault];
            require(adapter != address(0), 'ER001');
            require(asset != address(0), 'ER001');
            require(packetSize > 0, 'ER023');
            require((lockupPeriod >= MIN_LOCKUP && additionalRate == 0) || (additionalRate > 0 && lockupPeriod == 0), 'ER008');
            vaultAsset = IERC4626(adapter).asset();
        }
        require(asset == vaultAsset || PRICE_PROVIDER.pairHasOracle(vaultAsset, asset), 'ER033');
        poolId = _initPool(asset, vault, rate, additionalRate, lockupPeriod, packetSize);
        _getWalletForPool(poolId);
        _getWalletForFNFT(poolId);
        emit PoolCreated(poolId, asset, vault, vaultAsset, rate, additionalRate, lockupPeriod, packetSize, lockupPeriod > 0 && additionalRate == 0, poolName, msg.sender);
    }

    /**
     * @notice This function allows a participant to enter a pool on the Issuer side
     * @param poolId the pool in which to enter
     * @param amount the amount of tokens to deposit to that side of the pool – will be rounded down to nearest packet
     * @dev Gas prices will be highly dependent on the presence of counter-parties on the opposite side of the pool 
     */
    function submitConsumer(bytes32 poolId, uint amount, bool shouldFarm) external nonReentrant {
        PoolConfig memory pool = pools[poolId];
        require(amount > MIN_DEPOSIT, 'ER043');
        require(amount % pool.packetSize <= 5, 'ER005'); //be within 10 gwei to handle round-offs
        require(_validRecipient(), 'ER034');
        
        bool hasCounterparty = !_isQueueEmpty(poolId, true); // 2506 gas operation
        address vaultAsset;
        address adapter = pool.adapter;
        {
            IERC4626 vault = IERC4626(adapter);
            vaultAsset = vault.asset();
        }
        Order memory consumerOrder = Order(amount / pool.packetSize, 0, msg.sender.fillLast12Bytes());
        if(hasCounterparty) {
            IPoolWallet wallet = _getWalletForPool(poolId); 
            uint currentExchange;
            if (pool.asset != vaultAsset) {
                currentExchange = PRICE_PROVIDER.getValueOfAsset(vaultAsset, pool.asset);
            }
            while(hasCounterparty && consumerOrder.packetsRemaining > 0) {
                // Pull object for counterparty at head of queue
                Order storage producerOrder = _peek(poolId, true); // Not sure if I can make this memory because of Reentrancy concerns
                if(pool.asset != vaultAsset) {
                    uint previousExchange = producerOrder.depositedShares;
                    if(currentExchange != previousExchange) { // This will almost always be true
                        uint maxPacketNumber = producerOrder.packetsRemaining * previousExchange / currentExchange; // 5
                        uint amountToRefund;
                        if(consumerOrder.packetsRemaining >= maxPacketNumber) {
                            if(currentExchange > previousExchange) {
                                // Position is partially or fully insolvent
                                amountToRefund = pool.rate * pool.packetSize / PRECISION * ((producerOrder.packetsRemaining  * currentExchange) - (maxPacketNumber * previousExchange)) / PRECISION;
                                amountToRefund /= consumerOrder.packetsRemaining;
                            } else {
                                // There will be a surplus in the position
                                amountToRefund = pool.rate * pool.packetSize / PRECISION * ((maxPacketNumber * previousExchange) - (producerOrder.packetsRemaining  * currentExchange)) / PRECISION;
                            }
                        }
                        
                        if(maxPacketNumber == 0) {
                            // Need to cancel the order because it is totally insolvent
                            // No storage update

                            amountToRefund = pool.rate * pool.packetSize * producerOrder.packetsRemaining / PRECISION * previousExchange / PRECISION;

                            address orderOwner = producerOrder.owner.toAddress();
                            _dequeue(poolId, true);
                            wallet.withdraw(amountToRefund, 0, pool.asset, orderOwner, address(0));

                            hasCounterparty = !_isQueueEmpty(poolId, true);
                            continue;
                        }
                        // Storage update
                        producerOrder.depositedShares = currentExchange;
                        producerOrder.packetsRemaining = maxPacketNumber;

                        if(amountToRefund > 0) {
                            wallet.withdraw(amountToRefund, 0, pool.asset, DEV_ADDRESS, address(0));
                            emit FeeCollection(poolId, amountToRefund);
                        }
                    }
                }
                if(producerOrder.owner.toAddress() == address(0)) {
                    // Order has previously been cancelled
                    // Dequeue and move on to next iteration
                    // No storage update
                    _dequeue(poolId, true);
                } else {
                    uint digestAmt;
                    {
                        uint consumerAmt = consumerOrder.packetsRemaining;
                        uint producerAmt = producerOrder.packetsRemaining;
                        digestAmt = producerAmt >= consumerAmt ? consumerAmt : producerAmt;
                    }
                    _activateCapital(ParamPacker(consumerOrder, producerOrder, false, pool.asset != vaultAsset, digestAmt, currentExchange, pool, adapter, poolId));
                    
                    consumerOrder.packetsRemaining -= digestAmt;
                    producerOrder.packetsRemaining -= digestAmt; 

                    amount -= (digestAmt * pool.packetSize);

                    // Handle _dequeue as needed 
                    if (producerOrder.packetsRemaining == 0) {
                        _dequeue(poolId, true);
                    }
                }
                // Check if queue is empty
                hasCounterparty = !_isQueueEmpty(poolId, true);
            }
        } 

        
        if(!hasCounterparty && consumerOrder.packetsRemaining > 0) {
            // No currently available trade, add this order to consumer queue
            _enqueue(poolId, false, shouldFarm, consumerOrder, amount, vaultAsset, adapter);
        }
    }

    /**
     * @notice Allows a participant to enter a pool on the Purchaser side
     * @param poolId The ID of the pool in which to enter
     * @param amount The amount of tokens to deposit into the pool – will be rounded down to nearest packet
     * @param shouldFarm Whether or not to deposit the asset into a farm while it is queued. Not relevant if counter-party present or cross-asset pool
     * @dev shouldFarm is included to allow protocols to choose not to dilute their own yield farms while utilizing Resonate. It does not work for cross-assets
     */
    function submitProducer(bytes32 poolId, uint amount, bool shouldFarm) external nonReentrant {
        PoolConfig memory pool = pools[poolId];
        require(amount > MIN_DEPOSIT, 'ER043');
        require(_validRecipient(), 'ER034');
        
        Order memory producerOrder;

        bool hasCounterparty = !_isQueueEmpty(poolId, false);
        address vaultAsset;
        address adapter = pool.adapter;
        uint producerPacket;
        uint sharesPerPacket;
        {
            IERC4626 vault = IERC4626(adapter);
            vaultAsset = vault.asset();
            if (vaultAsset == pool.asset) {
                sharesPerPacket = shouldFarm ? 1 : 0;
                producerPacket = pool.packetSize * pool.rate / PRECISION;
                require(amount % producerPacket < 5, 'ER006');
            } else { 
                shouldFarm = false;
                sharesPerPacket = PRICE_PROVIDER.getValueOfAsset(vaultAsset, pool.asset);
                producerPacket = pool.rate * pool.packetSize / PRECISION * sharesPerPacket / PRECISION; 
                amount = amount / producerPacket * producerPacket;
                require(amount > 0, "ER003");
            }
            // Have relocated where deposits are made, are now towards end of workflow
            producerOrder = Order(uint112(amount/ producerPacket), sharesPerPacket, msg.sender.fillLast12Bytes());
        }
        if (hasCounterparty) {
            while(hasCounterparty && producerOrder.packetsRemaining > 0) {
                // Pull object for counterparty at head of queue
                Order storage consumerOrder = _peek(poolId, false);
                // Check edge-case
                if(consumerOrder.owner.toAddress() == address(0)) {
                    // Order has previously been cancelled
                    // Dequeue and move on to next iteration
                    _dequeue(poolId, false);
                } else {
                    // Perform calculations in terms of number of packets
                    uint digestAmt;
                    {
                        uint producerAmt = producerOrder.packetsRemaining;
                        uint consumerAmt = consumerOrder.packetsRemaining;
                        digestAmt = producerAmt >= consumerAmt ? consumerAmt : producerAmt;
                    }
                    _activateCapital(
                        ParamPacker(
                            consumerOrder, 
                            producerOrder, 
                            true, 
                            vaultAsset != pool.asset, 
                            digestAmt, 
                            producerOrder.depositedShares, 
                            pool, 
                            adapter, 
                            poolId
                        )
                    );

                    consumerOrder.packetsRemaining -= digestAmt;
                    producerOrder.packetsRemaining -= digestAmt;
                    amount -= (digestAmt * producerPacket);

                    // Handle _dequeue as needed
                    if(consumerOrder.packetsRemaining == 0) {
                        _dequeue(poolId, false);
                    }
                }
                // Check if queue is empty
                hasCounterparty = !_isQueueEmpty(poolId, false);
            }
        }


        if(!hasCounterparty && producerOrder.packetsRemaining > 0) {
            // If farming is desired, deposit remaining funds to farm
            // No currently available trade, add this order to producer queue
            _enqueue(poolId, true, shouldFarm, producerOrder, amount, pool.asset, adapter);
        }
    } 

    /** 
     * @notice Allows a participant to modify an existing order in-queue. User must own the position they are attempting to modify
     * @param poolId the ID of the pool in which the order exists
     * @param amount the amount of packets to withdraw from the order - will be rounded down to nearest packet
     * @param position the position of the order within the queue
     * @param isProvider on which side of the queue the order exists --- CAN LIKELY DEPRECATE
     * @dev Allows for orders to be withdrawn early. All revenue generated if the order was farming will be passed along to Resonate
     */
    function modifyExistingOrder(bytes32 poolId, uint112 amount, uint64 position, bool isProvider) external nonReentrant {
        // This function can withdraw tokens from an existing queued order and remove that order entirely if needed
        // amount = number of packets for order
        // if amount == packets remaining then just go and null out the rest of the order
        // delete sets the owner address to zero which is an edge case handled elsewhere

        Order memory order = isProvider ? providerQueue[poolId][position] : consumerQueue[poolId][position];
        require(msg.sender == order.owner.toAddress(), "ER007");

        //State changes
        if (order.packetsRemaining == amount) {
            PoolQueue storage qm = queueMarkers[poolId]; 
            emit OrderWithdrawal(poolId, amount, true, msg.sender);

            if (isProvider) {
                if (position == qm.providerHead) {
                    qm.providerHead++;
                }
                else if (position == qm.providerTail) {
                    qm.providerTail--;
                }
                delete providerQueue[poolId][position];
            } else {
                if (position == qm.consumerHead) {
                    qm.consumerHead++;
                } else if (position == qm.consumerTail) { 
                    qm.consumerTail--;
                }
                delete consumerQueue[poolId][position];
            }
        } else {
            if (isProvider) {
                providerQueue[poolId][position].packetsRemaining -= amount;
            } else {
                consumerQueue[poolId][position].packetsRemaining -= amount;
            }
            emit OrderWithdrawal(poolId, amount, false, msg.sender);
        }

        PoolConfig memory pool = pools[poolId];

        address asset = IERC4626(pool.adapter).asset();
        
        uint amountTokens = isProvider ? amount * pool.packetSize * pool.rate / PRECISION : amount * pool.packetSize;
        bool isCrossAsset = asset != pool.asset;

        if(order.depositedShares > 0 && (!isProvider || !isCrossAsset)) {

            // If is a farming consumer OR if is a farming position on the purchaser side that is not cross-asset

            uint tokensReceived = _getWalletForPool(poolId).withdrawFromVault(
                order.depositedShares * amount / PRECISION, // Recover extra PRECISION
                address(this), 
                pool.adapter
            );
            uint fee;
            if(tokensReceived > amountTokens) {
                fee = tokensReceived - amountTokens;
                IERC20(asset).safeTransfer(DEV_ADDRESS, fee);
            }
            IERC20(asset).safeTransfer(msg.sender, tokensReceived - fee);
        } else {
            if(isCrossAsset && isProvider) {
                // Is cross-asset purchaser, non-farming
                uint producerPacket = pool.rate * pool.packetSize / PRECISION * order.depositedShares / PRECISION;      
                    _getWalletForPool(poolId).withdraw(producerPacket * amount, 0, pool.asset, msg.sender, address(0));
               
            } else {
                // Is normal non-farming purchaser or non-farming consumer
                // Provider side, just withdraw
                _getWalletForPool(poolId).withdraw(amountTokens, 0, pool.asset, msg.sender, address(0));
            }
        }
    }

    /**
     * @notice Allows for the batch-claiming of interest from interest-bearing FNFTs
     * @param fnftIds A 2D array of FNFT Ids to be claimed. Should be formatted as arrays of FNFT Ids specific to pools for greater gas efficiency.
     * @param recipient The address to which the interest will be sent
     * @dev This function will revert if an inner array of FNFTs contains an ID with a poolID different from the first element in that array
     */
    function batchClaimInterest(uint[][] memory fnftIds, address recipient) public nonReentrant {
        // Outer array is an array of all FNFTs segregated by pool
        // Inner array is array of FNFTs to claim interest on
        uint numberPools = fnftIds.length;
        require(numberPools > 0, 'ER003');

        // for each pool
        for(uint i; i < numberPools; ++i) {
            // save the list of ids for the pool
            uint[] memory fnftsByPool = fnftIds[i];
            require(fnftsByPool.length > 0, 'ER003');

            // get the first order, we commit one SLOAD here
            bytes32 poolId = activated[fnftIdToIndex[fnftsByPool[0]]].poolId;
            PoolConfig memory pool = pools[poolId];
            IERC4626 vault = IERC4626(pool.adapter);
            address asset = vault.asset();

            // set up global to track total shares
            uint totalSharesToRedeem;
            // for each id, should be for loop
            uint len = fnftsByPool.length;
            for(uint j; j < len; ++j) {
                {
                    Active memory active = activated[fnftIdToIndex[fnftsByPool[j]]];
                    require(active.poolId == poolId, 'ER039');
                    // save the individual id
                    uint fnftId = fnftsByPool[j];
                    require(msg.sender == PROXY_OUTPUT_RECEIVER || FNFT_HANDLER.getBalance(msg.sender, fnftId) > 0, 'ER010');
                    require(fnftId == active.principalId + 1, 'ER009');
                    uint prinPackets = FNFT_HANDLER.getSupply(active.principalId);
                    require(prinPackets > 0, 'ER016');
                    uint oldShares = active.sharesPerPacket * prinPackets;
                    uint newShares = vault.previewWithdraw(pool.packetSize * prinPackets) * PRECISION; 
                    require(oldShares > newShares, 'ER040'); // Shouldn't pass FNFTs into this method that aren't owed interest
                    {
                        // Calculate the maximum number of shares that will be redeemed
                        uint sharesRedeemed = oldShares - newShares;   
                        // add to cumulative total
                        totalSharesToRedeem += sharesRedeemed;
                        // Update existing sharesPerPacket
                        activated[fnftIdToIndex[fnftId]].sharesPerPacket = newShares / prinPackets;
                    }
                }
            }
            uint interest = _getWalletForFNFT(poolId).redeemShares(
                pool.adapter, 
                address(this), 
                totalSharesToRedeem / PRECISION // recover extra precision
            );
            uint fee = interest * FEE / DENOM;
            IERC20(asset).transfer(DEV_ADDRESS, fee);
            // Forward to recipient
            IERC20(asset).transfer(recipient, interest-fee);
            emit FeeCollection(poolId, fee); 
            emit BatchInterestClaimed(poolId, fnftsByPool, recipient, interest);
        }
    }

    /**
     * @notice Claims the interest for a given position
     * @param fnftId the ID of the FNFT to claim interest on
     * @param recipient where that interest should be sent
     * @dev this function can either be called directly by the FNFT holder or through the OutputReceiver Proxy using the update method
     */
    function claimInterest(uint fnftId, address recipient) external override {
        uint[][] memory fnftIds = new uint[][](1);
        uint[] memory fnftIDi = new uint[](1);
        fnftIDi[0] = fnftId;
        fnftIds[0] = fnftIDi;
        batchClaimInterest(fnftIds, recipient);
    }
    
    ///
    /// Revest OutputReceiver functions
    /// 

    /**
     * @notice Handles the withdrawal behavior for both interest- and principal-bearing FNFTs
     * @param fnftId the ID of the FNFT being withdrawn 
     * @param tokenHolder The address to whom the principal or interest should be sent, as they owned the FNFT
     * @param quantity How many FNFTs are being withdrawn within the series. Will always be 1 for interest-bearing FNFTs
     * @dev Can only be called by the OutputReceiver Proxy contract. The FNFT associated with the ID will have been burned at the point this is called
     */
    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable tokenHolder,
        uint quantity
    ) external override nonReentrant {
        require(msg.sender == PROXY_OUTPUT_RECEIVER, "ER017");
        Active memory active = activated[fnftIdToIndex[fnftId]];
        PoolConfig memory pool = pools[active.poolId];
        uint prinPackets = FNFT_HANDLER.getSupply(active.principalId);        

        if(fnftId == active.principalId) {
            // This FNFT represents the principal
            // quantity = principalPackets
            // Need to withdraw principal, then record the residual interest owed
            uint amountUnderlying = quantity * pool.packetSize;
            bool leaveResidual = FNFT_HANDLER.getSupply(active.principalId + 1) > 0;
            address vaultAdapter = pool.adapter;
            
            // NB: Violation of checks-effects-interaction. Acceptable with nonReentrant
            uint residual = _getWalletForFNFT(active.poolId).reclaimPrincipal(
                vaultAdapter,
                tokenHolder, 
                amountUnderlying, 
                active.sharesPerPacket * quantity / PRECISION, // Recover our extra PRECISION here 
                leaveResidual
            );
            if(residual > 0) {
                residuals[fnftId + 1] += residual;
            }
            emit FNFTRedeemed(active.poolId, true, fnftId, quantity);
            emit InterestClaimed(active.poolId, fnftId, tokenHolder, residual);
            emit WithdrawERC20OutputReceiver(tokenHolder, IERC4626(vaultAdapter).asset(), amountUnderlying, fnftId, '0x0');
        } else {
            // This FNFT represents the interest
            require(quantity == 1, 'ER013');
            
            // Pass in totalShares, totalAmountPrincipal, derive interest and pull to this contract
            // Pull in any existing residuals within the same call – using residuals mapping?
            // Tell the vault to TRANSFER the residual (interest left when principal was pulled) 
            // plus WITHDRAW additional interest that has accrued
            // based on whatever principal remains within the vault 
            uint claimPerPacket;
            uint interest;
            
            {
                uint residual = residuals[fnftId];
                if(residual > 0) {
                    residuals[fnftId] = 0;
                }
                uint amountUnderlying = prinPackets * pool.packetSize;
                
                uint totalShares = active.sharesPerPacket * prinPackets / PRECISION; // Recover our extra PRECISION here

                // NB: Violation of checks-effects-interaction. Acceptable with nonReentrant
                (interest,claimPerPacket) = _getWalletForFNFT(active.poolId).reclaimInterestAndResidual(
                    pool.adapter, 
                    address(this), 
                    amountUnderlying, 
                    totalShares, 
                    residual
                );
            }

            if(prinPackets > 0) {
                // Add an extra PRECISION to avoid losing info
                claimPerPacket = claimPerPacket * PRECISION / prinPackets; 
                if(claimPerPacket <= active.sharesPerPacket) {
                    activated[fnftIdToIndex[fnftId]].sharesPerPacket = active.sharesPerPacket - claimPerPacket;
                } else {
                    activated[fnftIdToIndex[fnftId]].sharesPerPacket = 0;
                }
            }

            uint fee = interest * FEE / DENOM;
            address asset = IERC4626(pool.adapter).asset();

            IERC20(asset).safeTransfer(DEV_ADDRESS, fee);
            IERC20(asset).safeTransfer(tokenHolder, interest - fee);
            
            emit FNFTRedeemed(active.poolId, false, fnftId, 1);
            emit FeeCollection(active.poolId, fee);
            emit InterestClaimed(active.poolId, fnftId, tokenHolder, interest);
            // Remaining orphaned residual automatically goes to the principal FNFT holders
        }
        
        // Clean up mappings
        uint index = fnftIdToIndex[active.principalId];
        if(prinPackets == 0) {
            delete fnftIdToIndex[active.principalId];
        }
        if(FNFT_HANDLER.getSupply(active.principalId + 1) == 0) {
            delete fnftIdToIndex[active.principalId+1];
        }
        if(prinPackets == 0 && FNFT_HANDLER.getSupply(active.principalId + 1) == 0) { 
            delete activated[index];
        }
    }
        

    ///
    /// Utility Functions
    ///

    /**
     * @notice Takes two positions and matches them accordingly, creates FNFTs as-needed
     * @param packer Contains all the parameters needed for this operation
     * @dev If there was a deposit into the vault prior to capital activation for either order, claim that now and distribute
     */
    function _activateCapital(
        ParamPacker memory packer
    ) private returns (uint principalId) {
        // Double check in the future on the vaultAdapters
        IERC4626 vault = IERC4626(packer.adapter);
        address vaultAsset = vault.asset(); // The native asset
        // Fetch curPrice if necessary
        // State where it would be zero is when producer order is being submitted for non-farming position
        // Needs to come before FNFT creation, since curPrice is saved within that storage        

        // Need to withdraw from the vault for this operation if value was previously stored in it
        // Utilize this opportunity to charge fee on interest that has accumulated during dwell time
        uint amountFromConsumer = packer.quantityPackets * packer.pool.packetSize;
        uint amountToConsumer = packer.isCrossAsset ? amountFromConsumer * packer.pool.rate / PRECISION * packer.currentExchangeRate / PRECISION : amountFromConsumer * packer.pool.rate / PRECISION; //upfront?

        if(packer.isProducerNew) {
            {
                address consumerOwner = packer.consumerOrder.owner.toAddress();
                // The producer position is the new one, take value from them and transfer to consumer
                // Charge our fee on the upfront payment here
                uint fee = amountToConsumer * FEE / DENOM;
                IERC20(packer.pool.asset).safeTransferFrom(msg.sender, DEV_ADDRESS, fee);
                IERC20(packer.pool.asset).safeTransferFrom(msg.sender, consumerOwner, amountToConsumer-fee);
                emit FeeCollection(packer.poolId, fee);

                // Prepare the desired FNFTs
                principalId = _createFNFTs(packer.quantityPackets, packer.poolId, consumerOwner, packer.producerOrder.owner.toAddress());
            }
            
            // Order was previously farming
            {
                uint shares;
                if(packer.consumerOrder.depositedShares > 0) {
                    // Claim interest on the farming of the consumer's capital
                    (uint depositedShares, uint interest) = IPoolWallet(_getAddressForPool(packer.poolId)).activateExistingConsumerPosition(
                        amountFromConsumer, 
                        packer.quantityPackets * packer.consumerOrder.depositedShares / PRECISION, // Recover our extra precision
                        _getAddressForFNFT(packer.poolId), 
                        DEV_ADDRESS, 
                        packer.adapter
                    );
                    shares = depositedShares;
                    emit FeeCollection(packer.poolId, interest);
                } else {
                    // Position was not being farmed 
                    shares = IPoolWallet(_getAddressForPool(packer.poolId)).depositAndTransfer(
                        amountFromConsumer,
                        packer.adapter,
                        _getAddressForFNFT(packer.poolId)
                    );
                }
                // We want to avoid loss of information, so we multiply by 1E18 (PRECISION)
                shares = shares * PRECISION / packer.quantityPackets;

                Active storage active = activated[principalId];
                active.sharesPerPacket = shares;
                if(packer.pool.addInterestRate != 0) {
                    active.startingSharesPerPacket = shares;
                }
            }
        } else {
            // The consumer position is the new one, take stored producer value and transfer to them
            // If the producer was farming, we can detect this and charge our fee on interest

            address producerOwner = packer.producerOrder.owner.toAddress();

            // Need to deposit to vault from consumer and store in FNFT
            IERC20(vaultAsset).safeTransferFrom(msg.sender, address(this), amountFromConsumer);

            // Prepare the desired FNFTs
            principalId = _createFNFTs(packer.quantityPackets, packer.poolId, packer.consumerOrder.owner.toAddress(), producerOwner);
            {   
                Active storage active = activated[principalId];
                // We add an extra PRECISION to this to avoid losing data
                uint shares = vault.deposit(amountFromConsumer, _getAddressForFNFT(packer.poolId)) * PRECISION / packer.quantityPackets;
                active.sharesPerPacket = shares;
                if(packer.pool.addInterestRate != 0) {
                    active.startingSharesPerPacket = shares;
                }

            }
            

            // Need to then pay out to consumer from producer position
            if(packer.producerOrder.depositedShares > 0 && !packer.isCrossAsset) {
                
                uint interest = IPoolWallet(_getAddressForPool(packer.poolId)).activateExistingProducerPosition(
                    amountToConsumer, 
                    packer.quantityPackets * packer.producerOrder.depositedShares / PRECISION, // Recover our extra PRECISION here 
                    amountToConsumer * FEE / DENOM,
                    msg.sender, 
                    DEV_ADDRESS, 
                    packer.adapter
                );
                emit FeeCollection(packer.poolId, amountToConsumer * FEE / DENOM + interest);

            } else {
                uint fee = amountToConsumer * FEE / DENOM;
                IPoolWallet(_getAddressForPool(packer.poolId)).withdraw(amountToConsumer, fee, packer.pool.asset, msg.sender, DEV_ADDRESS);
            }
        } 
        emit CapitalActivated(packer.poolId, packer.quantityPackets, principalId);
        // Included to comply with IOutputReceiverV3 standard
        emit DepositERC20OutputReceiver(packer.consumerOrder.owner.toAddress(), vaultAsset, amountFromConsumer, principalId, '0x0');
    }

    /**
     * @notice Mints and distributes FNFTs, sends to each involved party
     * @param quantityPackets The number of packets being consumed by this order is the number of principal FNFTs to create
     * @param poolId The ID for the pool associated with these FNFTs
     * @param consumerOwner The owner of the Issuer's order, to whom the principal FNFTs will be minted
     * @param producerOwner The owner of the Purchaser's order, to whom the interest FNFT will be minted
     * @return principalId The ID of the principal-bearing FNFTs
     * @dev This function may be called multiple times for the creation of a single order with multiple counter-parties
     */
    function _createFNFTs(
        uint quantityPackets,
        bytes32 poolId,
        address consumerOwner, 
        address producerOwner
    ) private returns (uint principalId) {
        
        PoolConfig memory pool = pools[poolId];

        // We should know current deposit mul from previous work
        // Should have already deposited value by this point in workflow

        // Initialize base FNFT config
        IRevest.FNFTConfig memory fnftConfig;
        // Common method, both will reference this contract
        fnftConfig.pipeToContract = PROXY_OUTPUT_RECEIVER;
        // Further common components
        address[] memory recipients = new address[](1);
        uint[] memory quantities = new uint[](1);

        // Begin minting principal FNFTs

        quantities[0] = quantityPackets;
        recipients[0] = consumerOwner;

        if (pool.addInterestRate != 0) {
            // Mint Type 1 
            principalId = _getRevest().mintAddressLock(PROXY_ADDRESS_LOCK, "", recipients, quantities, fnftConfig);
        } else {
            // Mint Type 0
            principalId = _getRevest().mintTimeLock(block.timestamp + pool.lockupPeriod, recipients, quantities, fnftConfig);
        }

        // Begin minting interest FNFT

        // Interest FNFTs will always be singular
        // NB: Interest ID will always be +1 of principal ID
        quantities[0] = 1;
        recipients[0] = producerOwner;
        uint interestId;
        
        if (pool.addInterestRate != 0) {
            // Mint Type 1 
            interestId = _getRevest().mintAddressLock(PROXY_ADDRESS_LOCK, "", recipients, quantities, fnftConfig);  
        }  else {
            // Mint Type 0
            interestId = _getRevest().mintTimeLock(block.timestamp + pool.lockupPeriod, recipients, quantities, fnftConfig);
        }

        {

            activated[principalId] = Active(principalId, 1, 0, poolId);

            fnftIdToIndex[principalId] = principalId;
            fnftIdToIndex[interestId] = principalId;
        }

        emit FNFTCreation(poolId, true, principalId, quantityPackets);
        emit FNFTCreation(poolId, false, interestId, 1);
    }


    /**
     * @notice Add an order to the appropriate queue
     * @param poolId The ID of the pool to which this order should be added
     * @param isProvider Whether the order should be added to Purchaser queue (true) or Issuer queue (false)
     * @param shouldFarm Whether the user's tokens should be deposited into the underlying vault to farm in-queue
     * @param order The Order structure to add to the respective queue
     * @param amount The amount of tokens being deposited
     * @param asset The asset to deposit
     * @param vaultAdapter the ERC-4626 vault (adapter) to deposit into
     * @dev This should only be called once during either submitConsumer or submitProducer
     */
    function _enqueue(
        bytes32 poolId, 
        bool isProvider, 
        bool shouldFarm, 
        Order memory order, 
        uint amount, 
        address asset, 
        address vaultAdapter
    ) private {
        if(shouldFarm) {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

            order.depositedShares = IERC4626(vaultAdapter).deposit(amount, _getAddressForPool(poolId)) * PRECISION / order.packetsRemaining;
            require(order.depositedShares > 0, 'ER003'); 
        } else {
            // Leaving depositedShares as zero signifies non-farming nature of order
            // Similarly stores value in pool smart wallet
            IERC20(asset).safeTransferFrom(msg.sender, _getAddressForPool(poolId), amount);
        }

        PoolQueue storage qm = queueMarkers[poolId];
        // Allow overflow to reuse indices 
        unchecked {
            uint64 tail;
            if(isProvider) {
                tail = qm.providerTail;
                providerQueue[poolId][qm.providerTail++] = order;
                emit EnqueueProvider(poolId, msg.sender, tail, shouldFarm, order);
                
            } else {
                tail = qm.consumerTail;
                consumerQueue[poolId][qm.consumerTail++] = order;
                emit EnqueueConsumer(poolId, msg.sender, tail, shouldFarm, order);
            }
        }
    }   

    /**
     * @notice Remove an order from the appropriate queue 
     * @param poolId The ID of the pool which the order should be dequeued from
     * @param isProvider Whether the order should be removed from the Purchaser queue (true) or the Issuer queue (false)
     * @dev This can be called multiple times during the matching of counterparties
     */ 
    function _dequeue(bytes32 poolId, bool isProvider) private {
        PoolQueue storage qm = queueMarkers[poolId];
        Order memory order = providerQueue[poolId][isProvider ? qm.providerHead : qm.consumerHead];
        unchecked{
            uint64 head;
            if(isProvider) {
                head = qm.providerHead;
                delete providerQueue[poolId][qm.providerHead++];
                emit DequeueProvider(poolId, msg.sender, order.owner.toAddress(), head, order);
            } else {
                head = qm.consumerHead;
                delete consumerQueue[poolId][qm.consumerHead++];
                emit DequeueConsumer(poolId, msg.sender, order.owner.toAddress(), head, order);
            }
        }
    }

    /// Use to initialize necessary values for a pool
    /**
     * @notice Helper method to initialize the necessary values for a pool
     * @param asset the payment asset for the pool
     * @param vault the raw vault address for the pool - if non-4626 will have an adapter in vaultAdapters
     * @param rate the upfront payout rate for the pool
     * @param _additional_rate the value to be added to the rate to get the interest needed for unlock. Zero if fixed-term
     * @param lockupPeriod the amount of time in seconds that the principal FNFT will be locked for. Zero if fixed-income
     * @param packetSize the standard packet size for the pool
     * @return poolId the resulting poolId from the given parameters
     */
    function _initPool(
        address asset,
        address vault, 
        uint128 rate, 
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) private returns (bytes32 poolId) {
        address adapter = vaultAdapters[vault];
        poolId = _getPoolId(asset, vault, adapter, rate, _additional_rate, lockupPeriod, packetSize);
        require(pools[poolId].lockupPeriod == 0 && pools[poolId].addInterestRate == 0, 'ER002');
        queueMarkers[poolId] = PoolQueue(1, 1, 1, 1);
        pools[poolId] = PoolConfig(asset, vault, adapter, lockupPeriod, rate, _additional_rate, packetSize);
    }

    /**
     * @notice Fetches an instance of IPoolWallet, either by deploying or by instantiating an existing deployment
     * @param poolId The poolID to which this IPoolWallet is bound
     * @return wallet The instance of IPoolWallet associated with the passed-in poolId
     */
    function _getWalletForPool(bytes32 poolId) private returns (IPoolWallet wallet) {
        wallet = IPoolWallet(IResonateHelper(RESONATE_HELPER).getWalletForPool(poolId));
    }

    /**
     * @notice Fetches an instance of ISmartWallet, either by deploying or by instantiating an existing deployment
     * @param poolId The poolID to which this ISmartWallet is bound
     * @return wallet The instance of ISmartWallet associated with the passed-in poolId
     */
    function _getWalletForFNFT(bytes32 poolId) private returns (ISmartWallet wallet) {
        wallet = ISmartWallet(IResonateHelper(RESONATE_HELPER).getWalletForFNFT(poolId));
    }

    /**
     * @notice Checks whether a contract has approval to spend tokens from Resonate, approves if not so
     * @param spender The spender address to check, typically a smart wallet
     * @param asset The asset which will be spent
     */
    function _checkApproval(address spender, address asset) private {
        if(!_approvedContracts[spender][asset]) {
            IERC20(asset).safeApprove(spender, type(uint).max);
            _approvedContracts[spender][asset] = true;
        }
    }

    function _validRecipient() private view returns (bool canReceive) {
        uint size = msg.sender.code.length;
        bool isEOA = size == 0;
        canReceive = (msg.sender == tx.origin && isEOA) || SMART_WALLET_WHITELIST.check(msg.sender);
    }
     
    ///
    /// Admin Functions
    ///

    /**
     * @notice Used to match a vault with its adapter – can also be utilized for zero-ing out a vault
     * @param vault The raw vault which needs to be mapped to its adapter. If 4626, will be identical to adapter.
     * @param adapter The ERC-4626 adapter or vault to map to the baseline vault
     * @dev Protected function, vault MUST conform to ERC20 standard
     */
    function modifyVaultAdapter(address vault, address adapter) external onlyOwner {
        vaultAdapters[vault] = adapter;
        if(adapter != address(0)) {
            _checkApproval(adapter, IERC4626(adapter).asset());
            emit VaultAdapterRegistered(vault, adapter, IERC4626(adapter).asset());
        } else {
            emit VaultAdapterRegistered(vault, adapter, address(0));
        }
    }

    /**
     * @notice Transfer ownership to a new owner
     * @param newOwner The new owner to transfer control of admin functions to
     * @dev Protected function
     */
    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    ///
    /// View Functions
    ///

    /**
     * @notice Indicates whether a queue is empty on one side and therefore whether a counter-party is present
     * @param poolId The ID of the pool to check queues within
     * @param isProvider Whether to check the Purchaser queue (true) or the Issuer queue (false)
     * @return isEmpty Whether the queue being checked is empty or not
     */
    function _isQueueEmpty(bytes32 poolId, bool isProvider) private view returns (bool isEmpty) {
        PoolQueue memory qm = queueMarkers[poolId];
        isEmpty = isProvider ? qm.providerHead == qm.providerTail : qm.consumerHead == qm.consumerTail;
    }

    /**
     * @notice Retreive the poolId that a specified combination of inputs will produce
     * @param asset the payment asset for the pool
     * @param vault the raw vault address for the pool - if non-4626 will have an adapter in vaultAdapters
     * @param rate the upfront payout rate for the pool
     * @param _additional_rate the value to be added to the rate to get the interest needed for unlock. Zero if fixed-term
     * @param lockupPeriod the amount of time in seconds that the principal FNFT will be locked for. Zero if fixed-income
     * @param packetSize the standard packet size for the pool
     * @return poolId the result of applying keccak256 to the abi-encoded arguments passed in
     */
    function _getPoolId(
        address asset, 
        address vault, 
        address adapter,
        uint128 rate,
        uint128 _additional_rate,   
        uint32 lockupPeriod, 
        uint packetSize
    ) private pure returns (bytes32 poolId) {
        poolId = keccak256(abi.encodePacked(asset, vault, adapter, rate, _additional_rate, lockupPeriod, packetSize));
    }

    

    /**
     * @notice Returns the order at the head of the specified queue without removing it
     * @param poolId The poolId of the pool in which the queue exists
     * @param isProvider Whether to check the Purchaser queue (true) or the Issuer queue (false)
     * @return order The Order struct which is at the head of the specified queue
     */
    function _peek(bytes32 poolId, bool isProvider) private view returns (Order storage order) {
        if(isProvider) {
            order = providerQueue[poolId][queueMarkers[poolId].providerHead];
        } else {
            order = consumerQueue[poolId][queueMarkers[poolId].consumerHead];
        }
    }

    /**
     * @notice Returns the address of a pool smart wallet 
     */
    function _getAddressForPool(bytes32 poolId) private view returns (address smartWallet) {
        smartWallet = IResonateHelper(RESONATE_HELPER).getAddressForPool(poolId);
    }

    /**
     * @notice Returns the address of an FNFT pool smart wallet 
     */
    function _getAddressForFNFT(bytes32 poolId) private view returns (address smartWallet) {
        smartWallet = IResonateHelper(RESONATE_HELPER).getAddressForFNFT(poolId);
    }

    /// @notice Returns the IRevest entry point dictated by the Revest Address Registry
    function _getRevest() private view returns (IRevest) {
        return IRevest(IAddressRegistry(REGISTRY_ADDRESS).getRevest());
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4626 is IERC20 {


    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(address indexed caller, address indexed owner, uint256 amountUnderlying, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 amountUnderlying,
        uint256 shares
    );

    /// Transactional Functions

    function deposit(uint amountUnderlying, address receiver) external returns (uint shares);

    function mint(uint shares, address receiver) external returns (uint amountUnderlying);

    function withdraw(uint amountUnderlying, address receiver, address owner) external returns (uint shares);

    function redeem(uint shares, address receiver, address owner) external returns (uint amountUnderlying);


    /// View Functions

    function asset() external view returns (address assetTokenAddress);

    // Total assets held within
    function totalAssets() external view returns (uint totalManagedAssets);

    function convertToShares(uint amountUnderlying) external view returns (uint shares);

    function convertToAssets(uint shares) external view returns (uint amountUnderlying);

    function maxDeposit(address receiver) external view returns (uint maxAssets);

    function previewDeposit(uint amountUnderlying) external view returns (uint shares);

    function maxMint(address receiver) external view returns (uint maxShares);

    function previewMint(uint shares) external view returns (uint amountUnderlying);

    function maxWithdraw(address owner) external view returns (uint maxAssets);

    function previewWithdraw(uint amountUnderlying) external view returns (uint shares);

    function maxRedeem(address owner) external view returns (uint maxShares);

    function previewRedeem(uint shares) external view returns (uint amountUnderlying);

    /// IERC20 View Methods

    /**
     * @dev Returns the amount of shares in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of shares owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of shares that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Returns the name of the vault shares.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the vault shares.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the vault shares.
     */
    function decimals() external view returns (uint8);

    
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRevest {
    event FNFTTimeLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        uint endTime,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTValueLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address compareTo,
        address oracleDispatch,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTAddressLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address trigger,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTWithdrawn(
        address indexed from,
        uint indexed fnftId,
        uint indexed quantity
    );

    event FNFTSplit(
        address indexed from,
        uint[] indexed newFNFTId,
        uint[] indexed proportions,
        uint quantity
    );

    event FNFTUnlocked(
        address indexed from,
        uint indexed fnftId
    );

    event FNFTMaturityExtended(
        address indexed from,
        uint indexed fnftId,
        uint indexed newExtendedTime
    );

    event FNFTAddionalDeposited(
        address indexed from,
        uint indexed newFNFTId,
        uint indexed quantity,
        uint amount
    );

    struct FNFTConfig {
        address asset; // The token being stored
        address pipeToContract; // Indicates if FNFT will pipe to another contract
        uint depositAmount; // How many tokens
        uint depositMul; // Deposit multiplier
        uint split; // Number of splits remaining
        uint depositStopTime; //
        bool maturityExtension; // Maturity extensions remaining
        bool isMulti; //
        bool nontransferrable; // False by default (transferrable) //
    }

    // Refers to the global balance for an ERC20, encompassing possibly many FNFTs
    struct TokenTracker {
        uint lastBalance;
        uint lastMul;
    }

    enum LockType {
        DoesNotExist,
        TimeLock,
        ValueLock,
        AddressLock
    }

    struct LockParam {
        address addressLock;
        uint timeLockExpiry;
        LockType lockType;
        ValueLock valueLock;
    }

    struct Lock {
        address addressLock;
        LockType lockType;
        ValueLock valueLock;
        uint timeLockExpiry;
        uint creationTime;
        bool unlocked;
    }

    struct ValueLock {
        address asset;
        address compareTo;
        address oracle;
        uint unlockValue;
        bool unlockRisingEdge;
    }

    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function withdrawFNFT(uint tokenUID, uint quantity) external;

    function unlockFNFT(uint tokenUID) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external returns (uint[] memory newFNFTIds);

    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external returns (uint);

    function extendFNFTMaturity(
        uint fnftId,
        uint endTime
    ) external returns (uint);

    function setFlatWeiFee(uint wethFee) external;

    function setERC20Fee(uint erc20) external;

    function getFlatWeiFee() external view returns (uint);

    function getERC20Fee() external view returns (uint);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceProvider {

    event SetTokenOracle(address token, address oracle);

    function getSafePrice(address token) external view returns (uint256);

    function getCurrentPrice(address token) external view returns (uint256);

    function updateSafePrice(address token) external returns (uint256);

    /// Get value of an asset in units of quote
    function getValueOfAsset(address asset, address quote) external view returns (uint safePrice);

    function tokenHasOracle(address token) external view returns (bool hasOracle);

    function pairHasOracle(address token, address quote) external view returns (bool hasOracle);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IERC20Detailed {

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface ISmartWalletWhitelistV2 {
    function check(address) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/// @author RobAnon

interface ISmartWallet {

    function MASTER() external view returns (address master);

    function RESONATE() external view returns (address resonate);

    function reclaimPrincipal(
        address vaultAdapter, 
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        bool leaveResidual
    ) external returns (uint residual);

    function reclaimInterestAndResidual(
        address vaultAdapter, 
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        uint residual
    ) external returns (uint interest, uint sharesRedeemed);

    function redeemShares(
        address vaultAdapter,
        address receiver,
        uint totalShares
    ) external returns (uint amountUnderlying);

    //Future Proofing to allow for bribe system
    function proxyCall(address token, address vault, address vaultToken, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) external;

    function withdrawOrDeposit(address vaultAdapter, uint amount, bool isWithdrawal) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/// @author RobAnon

interface IPoolWallet {

    function MASTER() external view returns (address master);

    function RESONATE() external view returns (address resonate);

    function depositAndTransfer(uint amountTokens, address vaultAddress, address smartWallet) external returns (uint shares);

    function withdraw(uint value, uint fee, address token, address recipient, address devWallet) external;

    function withdrawFromVault(uint amount, address receiver, address vault) external returns (uint tokens);

    function activateExistingConsumerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        address fnftWallet,
        address devWallet,
        address vaultAdapter
    ) external returns (uint shares, uint interest);

    function activateExistingProducerPosition(
        uint amountUnderlying, 
        uint totalShares, 
        uint fee,
        address consumer,
        address devWallet,
        address vaultAdapter
    ) external returns (uint interest);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

library Bytes32Conversion {
    function toAddress(bytes32 b32) internal pure returns (address) {
        return address(uint160(bytes20(b32)));
    }
}

interface IResonate {

        // Uses 3 storage slots
    struct PoolConfig {
        address asset; // 20
        address vault; // 20 
        address adapter; // 20
        uint32  lockupPeriod; // 4
        uint128  rate; // 16
        uint128  addInterestRate; //Amount additional (10% on top of the 30%) - If not a bond then just zero // 16
        uint256 packetSize; // 32
    }

    // Uses 1 storage slot
    struct PoolQueue {
        uint64 providerHead;
        uint64 providerTail;
        uint64 consumerHead;
        uint64 consumerTail;
    }

    // Uses 3 storage slot
    struct Order {
        uint256 packetsRemaining;
        uint256 depositedShares;
        bytes32 owner;
    }

    struct ParamPacker {
        Order consumerOrder;
        Order producerOrder;
        bool isProducerNew;
        bool isCrossAsset;
        uint quantityPackets; 
        uint currentExchangeRate;
        PoolConfig pool;
        address adapter;
        bytes32 poolId;
    }

    /// Uses 4 storage slots
    /// Stores information on activated positions
    struct Active {
        // The ID of the associated Principal FNFT
        // Interest FNFT will be this +1
        uint256 principalId; 
        // Set at the time you last claim interest
        // Current state of interest - current shares per asset
        uint256 sharesPerPacket; 
        // Zero measurement point at pool creation
        // Left as zero if Type0
        uint256 startingSharesPerPacket; 
        bytes32 poolId;
    }

    ///
    /// Events
    ///

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event PoolCreated(bytes32 indexed poolId, address indexed asset, address indexed vault, address payoutAsset, uint128 rate, uint128 addInterestRate, uint32 lockupPeriod, uint256 packetSize, bool isFixedTerm, string poolName, address creator);

    event EnqueueProvider(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);
    event EnqueueConsumer(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);

    event DequeueProvider(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);
    event DequeueConsumer(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);

    event OracleRegistered(address indexed vaultAsset, address indexed paymentAsset, address indexed oracleDispatch);

    event VaultAdapterRegistered(address indexed underlyingVault, address indexed vaultAdapter, address indexed vaultAsset);

    event CapitalActivated(bytes32 indexed poolId, uint numPackets, uint indexed principalFNFT);
    
    event OrderWithdrawal(bytes32 indexed poolId, uint amountPackets, bool fullyWithdrawn, address owner);

    event FNFTCreation(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);
    event FNFTRedeemed(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);

    event FeeCollection(bytes32 indexed poolId, uint amountTokens);

    event InterestClaimed(bytes32 indexed poolId, uint indexed fnftId, address indexed claimer, uint amount);
    event BatchInterestClaimed(bytes32 indexed poolId, uint[] fnftIds, address indexed claimer, uint amountInterest);
    
    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);
    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    function residuals(uint fnftId) external view returns (uint residual);
    function RESONATE_HELPER() external view returns (address resonateHelper);

    function queueMarkers(bytes32 poolId) external view returns (uint64 a, uint64 b, uint64 c, uint64 d);
    function providerQueue(bytes32 poolId, uint256 providerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function consumerQueue(bytes32 poolId, uint256 consumerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function activated(uint fnftId) external view returns (uint principalId, uint sharesPerPacket, uint startingSharesPerPacket, bytes32 poolId);
    function pools(bytes32 poolId) external view returns (address asset, address vault, address adapter, uint32 lockupPeriod, uint128 rate, uint128 addInterestRate, uint256 packetSize);
    function vaultAdapters(address vault) external view returns (address vaultAdapter);
    function fnftIdToIndex(uint fnftId) external view returns (uint index);
    function REGISTRY_ADDRESS() external view returns (address registry);

    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable owner,
        uint quantity
    ) external;

    function claimInterest(uint fnftId, address recipient) external;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./IResonate.sol";

/// @author RobAnon

interface IResonateHelper {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address owner);

    function POOL_TEMPLATE() external view returns (address template);

    function FNFT_TEMPLATE() external view returns (address template);

    function SANDWICH_BOT_ADDRESS() external view returns (address bot);

    function getAddressForPool(bytes32 poolId) external view returns (address smartWallet);

    function getAddressForFNFT(bytes32 fnftId) external view returns (address smartWallet);

    function getWalletForPool(bytes32 poolId) external returns (address smartWallet);

    function getWalletForFNFT(bytes32 fnftId) external returns (address wallet);


    function setResonate(address resonate) external;

    function blackListFunction(uint32 selector) external;
    function whiteListFunction(uint32 selector, bool isWhitelisted) external;

    /// To be used by the sandwich bot for bribe system. Can only withdraw assets back to vault not externally
    function sandwichSnapshot(bytes32 poolId, uint amount, bool isWithdrawal) external;
    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external;
    ///
    /// VIEW METHODS
    ///

    function getPoolId(
        address asset, 
        address vault,
        address adapter, 
        uint128 rate,
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) external pure returns (bytes32 poolId);

    function nextInQueue(bytes32 poolId, bool isProvider) external view returns (IResonate.Order memory order);

    function isQueueEmpty(bytes32 poolId, bool isProvider) external view returns (bool isEmpty);

    function calculateInterest(uint fnftId) external view returns (uint256 interest, uint256 interestAfterFee);

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFNFTHandler  {
    function mint(address account, uint id, uint amount, bytes memory data) external;

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external;

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

    function setURI(string memory newuri) external;

    function burn(address account, uint id, uint amount) external;

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external;

    function getBalance(address tokenHolder, uint id) external view returns (uint);

    function getSupply(uint fnftId) external view returns (uint);

    function getNextId() external view returns (uint);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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