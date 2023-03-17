// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "ComponentController.sol";
import "PolicyController.sol";
import "BundleController.sol";
import "PoolController.sol";
import "CoreController.sol";
import "TransferHelper.sol";

import "IComponent.sol";
import "IProduct.sol";
import "IPolicy.sol";
import "ITreasury.sol";

import "Pausable.sol";
import "IERC20.sol";
import "Strings.sol";

contract TreasuryModule is 
    ITreasury,
    CoreController,
    Pausable
{
    uint256 public constant FRACTION_FULL_UNIT = 10**18;
    uint256 public constant FRACTIONAL_FEE_MAX = FRACTION_FULL_UNIT / 4; // max frctional fee is 25%

    event LogTransferHelperInputValidation1Failed(bool tokenIsContract, address from, address to);
    event LogTransferHelperInputValidation2Failed(uint256 balance, uint256 allowance);
    event LogTransferHelperCallFailed(bool callSuccess, uint256 returnDataLength, bytes returnData);

    address private _instanceWalletAddress;
    mapping(uint256 => address) private _riskpoolWallet; // riskpoolId => walletAddress
    mapping(uint256 => FeeSpecification) private _fees; // componentId => fee specification
    mapping(uint256 => IERC20) private _componentToken; // productId/riskpoolId => erc20Address

    BundleController private _bundle;
    ComponentController private _component;
    PolicyController private _policy;
    PoolController private _pool;

    modifier instanceWalletDefined() {
        require(
            _instanceWalletAddress != address(0),
            "ERROR:TRS-001:INSTANCE_WALLET_UNDEFINED");
        _;
    }

    modifier riskpoolWalletDefinedForProcess(bytes32 processId) {
        (uint256 riskpoolId, address walletAddress) = _getRiskpoolWallet(processId);
        require(
            walletAddress != address(0),
            "ERROR:TRS-002:RISKPOOL_WALLET_UNDEFINED");
        _;
    }

    modifier riskpoolWalletDefinedForBundle(uint256 bundleId) {
        IBundle.Bundle memory bundle = _bundle.getBundle(bundleId);
        require(
            getRiskpoolWallet(bundle.riskpoolId) != address(0),
            "ERROR:TRS-003:RISKPOOL_WALLET_UNDEFINED");
        _;
    }

    // surrogate modifier for whenNotPaused to create treasury specific error message
    modifier whenNotSuspended() {
        require(!paused(), "ERROR:TRS-004:TREASURY_SUSPENDED");
        _;
    }

    modifier onlyRiskpoolService() {
        require(
            _msgSender() == _getContractAddress("RiskpoolService"),
            "ERROR:TRS-005:NOT_RISKPOOL_SERVICE"
        );
        _;
    }

    function _afterInitialize() internal override onlyInitializing {
        _bundle = BundleController(_getContractAddress("Bundle"));
        _component = ComponentController(_getContractAddress("Component"));
        _policy = PolicyController(_getContractAddress("Policy"));
        _pool = PoolController(_getContractAddress("Pool"));
    }

    function suspend() 
        external 
        onlyInstanceOperator
    {
        _pause();
        emit LogTreasurySuspended();
    }

    function resume() 
        external 
        onlyInstanceOperator
    {
        _unpause();
        emit LogTreasuryResumed();
    }

    function setProductToken(uint256 productId, address erc20Address)
        external override
        whenNotSuspended
        onlyInstanceOperator
    {
        require(erc20Address != address(0), "ERROR:TRS-010:TOKEN_ADDRESS_ZERO");

        IComponent component = _component.getComponent(productId);
        require(_component.isProduct(productId), "ERROR:TRS-011:NOT_PRODUCT");
        require(address(_componentToken[productId]) == address(0), "ERROR:TRS-012:PRODUCT_TOKEN_ALREADY_SET");
    
        uint256 riskpoolId = _pool.getRiskPoolForProduct(productId);

        // require if riskpool token is already set and product token does match riskpool token
        require(address(_componentToken[riskpoolId]) == address(0)
                || address(_componentToken[riskpoolId]) == address(IProduct(address(component)).getToken()), 
                "ERROR:TRS-014:TOKEN_ADDRESS_NOT_MACHING");
        
        _componentToken[productId] = IERC20(erc20Address);
        _componentToken[riskpoolId] = IERC20(erc20Address);

        emit LogTreasuryProductTokenSet(productId, riskpoolId, erc20Address);
    }

    function setInstanceWallet(address instanceWalletAddress) 
        external override
        whenNotSuspended
        onlyInstanceOperator
    {
        require(instanceWalletAddress != address(0), "ERROR:TRS-015:WALLET_ADDRESS_ZERO");
        _instanceWalletAddress = instanceWalletAddress;

        emit LogTreasuryInstanceWalletSet (instanceWalletAddress);
    }

    function setRiskpoolWallet(uint256 riskpoolId, address riskpoolWalletAddress) 
        external override
        whenNotSuspended
        onlyInstanceOperator
    {
        IComponent component = _component.getComponent(riskpoolId);
        require(_component.isRiskpool(riskpoolId), "ERROR:TRS-016:NOT_RISKPOOL");
        require(riskpoolWalletAddress != address(0), "ERROR:TRS-017:WALLET_ADDRESS_ZERO");
        _riskpoolWallet[riskpoolId] = riskpoolWalletAddress;

        emit LogTreasuryRiskpoolWalletSet (riskpoolId, riskpoolWalletAddress);
    }

    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    )
        external override
        view 
        returns(FeeSpecification memory)
    {
        require(_component.isProduct(componentId) || _component.isRiskpool(componentId), "ERROR:TRS-020:ID_NOT_PRODUCT_OR_RISKPOOL");
        require(fractionalFee <= FRACTIONAL_FEE_MAX, "ERROR:TRS-021:FRACIONAL_FEE_TOO_BIG");

        return FeeSpecification(
            componentId,
            fixedFee,
            fractionalFee,
            feeCalculationData,
            block.timestamp,  // solhint-disable-line
            block.timestamp   // solhint-disable-line
        ); 
    }

    function setPremiumFees(FeeSpecification calldata feeSpec) 
        external override
        whenNotSuspended
        onlyInstanceOperator
    {
        require(_component.isProduct(feeSpec.componentId), "ERROR:TRS-022:NOT_PRODUCT");
        
        // record  original creation timestamp 
        uint256 originalCreatedAt = _fees[feeSpec.componentId].createdAt;
        _fees[feeSpec.componentId] = feeSpec;

        // set original creation timestamp if fee spec already existed
        if (originalCreatedAt > 0) {
            _fees[feeSpec.componentId].createdAt = originalCreatedAt;
        }

        emit LogTreasuryPremiumFeesSet (
            feeSpec.componentId,
            feeSpec.fixedFee, 
            feeSpec.fractionalFee);
    }


    function setCapitalFees(FeeSpecification calldata feeSpec) 
        external override
        whenNotSuspended
        onlyInstanceOperator
    {
        require(_component.isRiskpool(feeSpec.componentId), "ERROR:TRS-023:NOT_RISKPOOL");

        // record  original creation timestamp 
        uint256 originalCreatedAt = _fees[feeSpec.componentId].createdAt;
        _fees[feeSpec.componentId] = feeSpec;

        // set original creation timestamp if fee spec already existed
        if (originalCreatedAt > 0) {
            _fees[feeSpec.componentId].createdAt = originalCreatedAt;
        }

        emit LogTreasuryCapitalFeesSet (
            feeSpec.componentId,
            feeSpec.fixedFee, 
            feeSpec.fractionalFee);
    }


    function calculateFee(uint256 componentId, uint256 amount)
        public 
        view
        returns(uint256 feeAmount, uint256 netAmount)
    {
        FeeSpecification memory feeSpec = getFeeSpecification(componentId);
        require(feeSpec.createdAt > 0, "ERROR:TRS-024:FEE_SPEC_UNDEFINED");
        feeAmount = _calculateFee(feeSpec, amount);
        netAmount = amount - feeAmount;
    }
    

    /*
     * Process the remaining premium by calculating the remaining amount, the fees for that amount and 
     * then transfering the fees to the instance wallet and the net premium remaining to the riskpool. 
     * This will revert if no fee structure is defined. 
     */
    function processPremium(bytes32 processId) 
        external override 
        whenNotSuspended
        onlyPolicyFlow("Treasury")
        returns(
            bool success, 
            uint256 feeAmount, 
            uint256 netPremiumAmount
        ) 
    {
        IPolicy.Policy memory policy =  _policy.getPolicy(processId);

        if (policy.premiumPaidAmount < policy.premiumExpectedAmount) {
            (success, feeAmount, netPremiumAmount) 
                = processPremium(processId, policy.premiumExpectedAmount - policy.premiumPaidAmount);
        }
    }

    /*
     * Process the premium by calculating the fees for the amount and 
     * then transfering the fees to the instance wallet and the net premium to the riskpool. 
     * This will revert if no fee structure is defined. 
     */
    function processPremium(bytes32 processId, uint256 amount) 
        public override 
        whenNotSuspended
        instanceWalletDefined
        riskpoolWalletDefinedForProcess(processId)
        onlyPolicyFlow("Treasury")
        returns(
            bool success, 
            uint256 feeAmount, 
            uint256 netAmount
        ) 
    {
        IPolicy.Policy memory policy =  _policy.getPolicy(processId);
        require(
            policy.premiumPaidAmount + amount <= policy.premiumExpectedAmount, 
            "ERROR:TRS-030:AMOUNT_TOO_BIG"
        );

        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        (feeAmount, netAmount) 
            = calculateFee(metadata.productId, amount);

        // check if allowance covers requested amount
        IERC20 token = getComponentToken(metadata.productId);
        if (token.allowance(metadata.owner, address(this)) < amount) {
            success = false;
            return (success, feeAmount, netAmount);
        }

        // collect premium fees
        success = TransferHelper.unifiedTransferFrom(token, metadata.owner, _instanceWalletAddress, feeAmount);
        emit LogTreasuryFeesTransferred(metadata.owner, _instanceWalletAddress, feeAmount);
        require(success, "ERROR:TRS-031:FEE_TRANSFER_FAILED");

        // transfer premium net amount to riskpool for product
        // actual transfer of net premium to riskpool
        (uint256 riskpoolId, address riskpoolWalletAddress) = _getRiskpoolWallet(processId);
        success = TransferHelper.unifiedTransferFrom(token, metadata.owner, riskpoolWalletAddress, netAmount);

        emit LogTreasuryPremiumTransferred(metadata.owner, riskpoolWalletAddress, netAmount);
        require(success, "ERROR:TRS-032:PREMIUM_TRANSFER_FAILED");

        emit LogTreasuryPremiumProcessed(processId, amount);
    }


    function processPayout(bytes32 processId, uint256 payoutId) 
        external override
        whenNotSuspended
        instanceWalletDefined
        riskpoolWalletDefinedForProcess(processId)
        onlyPolicyFlow("Treasury")
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        )
    {
        IPolicy.Payout memory payout =  _policy.getPayout(processId, payoutId);
        require(
            payout.state == IPolicy.PayoutState.Expected, 
            "ERROR:TRS-040:PAYOUT_ALREADY_PROCESSED"
        );

        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        IERC20 token = getComponentToken(metadata.productId);
        (uint256 riskpoolId, address riskpoolWalletAddress) = _getRiskpoolWallet(processId);

        require(
            token.balanceOf(riskpoolWalletAddress) >= payout.amount, 
            "ERROR:TRS-042:RISKPOOL_WALLET_BALANCE_TOO_SMALL"
        );
        require(
            token.allowance(riskpoolWalletAddress, address(this)) >= payout.amount, 
            "ERROR:TRS-043:PAYOUT_ALLOWANCE_TOO_SMALL"
        );

        // actual payout to policy holder
        bool success = TransferHelper.unifiedTransferFrom(token, riskpoolWalletAddress, metadata.owner, payout.amount);
        feeAmount = 0;
        netPayoutAmount = payout.amount;

        emit LogTreasuryPayoutTransferred(riskpoolWalletAddress, metadata.owner, payout.amount);
        require(success, "ERROR:TRS-044:PAYOUT_TRANSFER_FAILED");

        emit LogTreasuryPayoutProcessed(riskpoolId,  metadata.owner, payout.amount);
    }

    function processCapital(uint256 bundleId, uint256 capitalAmount) 
        external override 
        whenNotSuspended
        instanceWalletDefined
        riskpoolWalletDefinedForBundle(bundleId)
        onlyRiskpoolService
        returns(
            uint256 feeAmount,
            uint256 netCapitalAmount
        )
    {
        // obtain relevant fee specification
        IBundle.Bundle memory bundle = _bundle.getBundle(bundleId);
        address bundleOwner = _bundle.getOwner(bundleId);

        FeeSpecification memory feeSpec = getFeeSpecification(bundle.riskpoolId);
        require(feeSpec.createdAt > 0, "ERROR:TRS-050:FEE_SPEC_UNDEFINED");

        // obtain relevant token for product/riskpool pair
        IERC20 token = _componentToken[bundle.riskpoolId];

        // calculate fees and net capital
        feeAmount = _calculateFee(feeSpec, capitalAmount);
        netCapitalAmount = capitalAmount - feeAmount;

        // check balance and allowance before starting any transfers
        require(token.balanceOf(bundleOwner) >= capitalAmount, "ERROR:TRS-052:BALANCE_TOO_SMALL");
        require(token.allowance(bundleOwner, address(this)) >= capitalAmount, "ERROR:TRS-053:CAPITAL_TRANSFER_ALLOWANCE_TOO_SMALL");

        bool success = TransferHelper.unifiedTransferFrom(token, bundleOwner, _instanceWalletAddress, feeAmount);

        emit LogTreasuryFeesTransferred(bundleOwner, _instanceWalletAddress, feeAmount);
        require(success, "ERROR:TRS-054:FEE_TRANSFER_FAILED");

        // transfer net capital
        address riskpoolWallet = getRiskpoolWallet(bundle.riskpoolId);
        success = TransferHelper.unifiedTransferFrom(token, bundleOwner, riskpoolWallet, netCapitalAmount);

        emit LogTreasuryCapitalTransferred(bundleOwner, riskpoolWallet, netCapitalAmount);
        require(success, "ERROR:TRS-055:CAPITAL_TRANSFER_FAILED");

        emit LogTreasuryCapitalProcessed(bundle.riskpoolId, bundleId, capitalAmount);
    }

    function processWithdrawal(uint256 bundleId, uint256 amount) 
        external override
        whenNotSuspended
        instanceWalletDefined
        riskpoolWalletDefinedForBundle(bundleId)
        onlyRiskpoolService
        returns(
            uint256 feeAmount,
            uint256 netAmount
        )
    {
        // obtain relevant bundle info
        IBundle.Bundle memory bundle = _bundle.getBundle(bundleId);
        require(
            bundle.capital >= bundle.lockedCapital + amount
            || (bundle.lockedCapital == 0 && bundle.balance >= amount),
            "ERROR:TRS-060:CAPACITY_OR_BALANCE_SMALLER_THAN_WITHDRAWAL"
        );

        // obtain relevant token for product/riskpool pair
        address riskpoolWallet = getRiskpoolWallet(bundle.riskpoolId);
        address bundleOwner = _bundle.getOwner(bundleId);
        IERC20 token = _componentToken[bundle.riskpoolId];

        require(
            token.balanceOf(riskpoolWallet) >= amount, 
            "ERROR:TRS-061:RISKPOOL_WALLET_BALANCE_TOO_SMALL"
        );
        require(
            token.allowance(riskpoolWallet, address(this)) >= amount, 
            "ERROR:TRS-062:WITHDRAWAL_ALLOWANCE_TOO_SMALL"
        );

        // TODO consider to introduce withdrawal fees
        // ideally symmetrical reusing capital fee spec for riskpool
        feeAmount = 0;
        netAmount = amount;
        bool success = TransferHelper.unifiedTransferFrom(token, riskpoolWallet, bundleOwner, netAmount);

        emit LogTreasuryWithdrawalTransferred(riskpoolWallet, bundleOwner, netAmount);
        require(success, "ERROR:TRS-063:WITHDRAWAL_TRANSFER_FAILED");

        emit LogTreasuryWithdrawalProcessed(bundle.riskpoolId, bundleId, netAmount);
    }


    function getComponentToken(uint256 componentId) 
        public override
        view
        returns(IERC20 token) 
    {
        require(_component.isProduct(componentId) || _component.isRiskpool(componentId), "ERROR:TRS-070:NOT_PRODUCT_OR_RISKPOOL");
        return _componentToken[componentId];
    }

    function getFeeSpecification(uint256 componentId) public override view returns(FeeSpecification memory) {
        return _fees[componentId];
    }

    function getFractionFullUnit() public override pure returns(uint256) { 
        return FRACTION_FULL_UNIT; 
    }

    function getInstanceWallet() public override view returns(address) { 
        return _instanceWalletAddress; 
    }

    function getRiskpoolWallet(uint256 riskpoolId) public override view returns(address) {
        return _riskpoolWallet[riskpoolId];
    }


    function _calculatePremiumFee(
        FeeSpecification memory feeSpec, 
        bytes32 processId
    )
        internal
        view
        returns (
            IPolicy.Application memory application, 
            uint256 feeAmount
        )
    {
        application =  _policy.getApplication(processId);
        feeAmount = _calculateFee(feeSpec, application.premiumAmount);
    } 


    function _calculateFee(
        FeeSpecification memory feeSpec, 
        uint256 amount
    )
        internal
        pure
        returns (uint256 feeAmount)
    {
        if (feeSpec.feeCalculationData.length > 0) {
            revert("ERROR:TRS-090:FEE_CALCULATION_DATA_NOT_SUPPORTED");
        }

        // start with fixed fee
        feeAmount = feeSpec.fixedFee;

        // add fractional fee on top
        if (feeSpec.fractionalFee > 0) {
            feeAmount += (feeSpec.fractionalFee * amount) / FRACTION_FULL_UNIT;
        }

        // require that fee is smaller than amount
        require(feeAmount < amount, "ERROR:TRS-091:FEE_TOO_BIG");
    } 

    function _getRiskpoolWallet(bytes32 processId)
        internal
        view
        returns(uint256 riskpoolId, address riskpoolWalletAddress)
    {
        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        riskpoolId = _pool.getRiskPoolForProduct(metadata.productId);
        require(riskpoolId > 0, "ERROR:TRS-092:PRODUCT_WITHOUT_RISKPOOL");
        riskpoolWalletAddress = _riskpoolWallet[riskpoolId];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "CoreController.sol";
import "IComponent.sol";
import "IOracle.sol";
import "IProduct.sol";
import "IRiskpool.sol";
import "IComponentEvents.sol";
import "EnumerableSet.sol";

contract ComponentController is
    IComponentEvents,
    CoreController 
 {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => IComponent) private _componentById;
    mapping(bytes32 => uint256) private _componentIdByName;
    mapping(address => uint256) private _componentIdByAddress;

    mapping(uint256 => IComponent.ComponentState) private _componentState;

    EnumerableSet.UintSet private _products;
    EnumerableSet.UintSet private _oracles;
    EnumerableSet.UintSet private _riskpools;
    uint256 private _componentCount;

    mapping(uint256 /* product id */ => address /* policy flow address */) private _policyFlowByProductId;

    modifier onlyComponentOwnerService() {
        require(
            _msgSender() == _getContractAddress("ComponentOwnerService"),
            "ERROR:CCR-001:NOT_COMPONENT_OWNER_SERVICE");
        _;
    }

    modifier onlyInstanceOperatorService() {
        require(
            _msgSender() == _getContractAddress("InstanceOperatorService"),
            "ERROR:CCR-002:NOT_INSTANCE_OPERATOR_SERVICE");
        _;
    }

    function propose(IComponent component) 
        external
        onlyComponentOwnerService 
    {
        // input validation
        require(_componentIdByAddress[address(component)] == 0, "ERROR:CCR-003:COMPONENT_ALREADY_EXISTS");
        require(_componentIdByName[component.getName()] == 0, "ERROR:CCR-004:COMPONENT_NAME_ALREADY_EXISTS");

        // assigning id and persisting component
        uint256 id = _persistComponent(component);

        // log entry for successful proposal
        emit LogComponentProposed(
            component.getName(),
            component.getType(),
            address(component),
            id);
        
        // inform component about successful proposal
        component.proposalCallback();
    }

    function _persistComponent(IComponent component) 
        internal
        returns(uint256 id)
    {
        // fetch next component id
        _componentCount++;
        id = _componentCount;

        // update component state
        _changeState(id, IComponent.ComponentState.Proposed);
        component.setId(id);

        // update controller book keeping
        _componentById[id] = component;
        _componentIdByName[component.getName()] = id;
        _componentIdByAddress[address(component)] = id;

        // type specific book keeping
        if (component.isProduct()) { EnumerableSet.add(_products, id); }
        else if (component.isOracle()) { EnumerableSet.add(_oracles, id); }
        else if (component.isRiskpool()) { EnumerableSet.add(_riskpools, id); }
    }

    function exists(uint256 id) public view returns(bool) {
        IComponent component = _componentById[id];
        return (address(component) != address(0));
    }

    function approve(uint256 id) 
        external
        onlyInstanceOperatorService 
    {
        _changeState(id, IComponent.ComponentState.Active);
        IComponent component = getComponent(id);

        if (isProduct(id)) {
            _policyFlowByProductId[id] = IProduct(address(component)).getPolicyFlow();
        }

        emit LogComponentApproved(id);
        
        // inform component about successful approval
        component.approvalCallback();
    }

    function decline(uint256 id) 
        external
        onlyInstanceOperatorService 
    {
        _changeState(id, IComponent.ComponentState.Declined);
        emit LogComponentDeclined(id);
        
        // inform component about decline
        IComponent component = getComponent(id);
        component.declineCallback();
    }

    function suspend(uint256 id) 
        external 
        onlyInstanceOperatorService 
    {
        _changeState(id, IComponent.ComponentState.Suspended);
        emit LogComponentSuspended(id);
        
        // inform component about suspending
        IComponent component = getComponent(id);
        component.suspendCallback();
    }

    function resume(uint256 id) 
        external 
        onlyInstanceOperatorService 
    {
        _changeState(id, IComponent.ComponentState.Active);
        emit LogComponentResumed(id);
        
        // inform component about resuming
        IComponent component = getComponent(id);
        component.resumeCallback();
    }

    function pause(uint256 id) 
        external 
        onlyComponentOwnerService 
    {
        _changeState(id, IComponent.ComponentState.Paused);
        emit LogComponentPaused(id);
        
        // inform component about pausing
        IComponent component = getComponent(id);
        component.pauseCallback();
    }

    function unpause(uint256 id) 
        external 
        onlyComponentOwnerService 
    {
        _changeState(id, IComponent.ComponentState.Active);
        emit LogComponentUnpaused(id);
        
        // inform component about unpausing
        IComponent component = getComponent(id);
        component.unpauseCallback();
    }

    function archiveFromComponentOwner(uint256 id) 
        external 
        onlyComponentOwnerService 
    {
        _changeState(id, IComponent.ComponentState.Archived);
        emit LogComponentArchived(id);
        
        // inform component about archiving
        IComponent component = getComponent(id);
        component.archiveCallback();
    }

    function archiveFromInstanceOperator(uint256 id) 
        external 
        onlyInstanceOperatorService 
    {
        _changeState(id, IComponent.ComponentState.Archived);
        emit LogComponentArchived(id);
        
        // inform component about archiving
        IComponent component = getComponent(id);
        component.archiveCallback();
    }

    function getComponent(uint256 id) public view returns (IComponent component) {
        component = _componentById[id];
        require(address(component) != address(0), "ERROR:CCR-005:INVALID_COMPONENT_ID");
    }

    function getComponentId(address componentAddress) public view returns (uint256 id) {
        require(componentAddress != address(0), "ERROR:CCR-006:COMPONENT_ADDRESS_ZERO");
        id = _componentIdByAddress[componentAddress];

        require(id > 0, "ERROR:CCR-007:COMPONENT_UNKNOWN");
    }

    function getComponentType(uint256 id) public view returns (IComponent.ComponentType componentType) {
        if (EnumerableSet.contains(_products, id)) {
            return IComponent.ComponentType.Product;
        } else if (EnumerableSet.contains(_oracles, id)) {
            return IComponent.ComponentType.Oracle;
        } else if (EnumerableSet.contains(_riskpools, id)) {
            return IComponent.ComponentType.Riskpool;
        } else {
            revert("ERROR:CCR-008:INVALID_COMPONENT_ID");
        }
    }

    function getComponentState(uint256 id) public view returns (IComponent.ComponentState componentState) {
        return _componentState[id];
    }

    function getOracleId(uint256 idx) public view returns (uint256 oracleId) {
        return EnumerableSet.at(_oracles, idx);
    }

    function getRiskpoolId(uint256 idx) public view returns (uint256 riskpoolId) {
        return EnumerableSet.at(_riskpools, idx);
    }

    function getProductId(uint256 idx) public view returns (uint256 productId) {
        return EnumerableSet.at(_products, idx);
    }

    function getRequiredRole(IComponent.ComponentType componentType) external view returns (bytes32) {
        if (componentType == IComponent.ComponentType.Product) { return _access.getProductOwnerRole(); }
        else if (componentType == IComponent.ComponentType.Oracle) { return _access.getOracleProviderRole(); }
        else if (componentType == IComponent.ComponentType.Riskpool) { return _access.getRiskpoolKeeperRole(); }
        else { revert("ERROR:CCR-010:COMPONENT_TYPE_UNKNOWN"); }
    }

    function components() public view returns (uint256 count) { return _componentCount; }
    function products() public view returns (uint256 count) { return EnumerableSet.length(_products); }
    function oracles() public view returns (uint256 count) { return EnumerableSet.length(_oracles); }
    function riskpools() public view returns (uint256 count) { return EnumerableSet.length(_riskpools); }

    function isProduct(uint256 id) public view returns (bool) { return EnumerableSet.contains(_products, id); }

    function isOracle(uint256 id) public view returns (bool) { return EnumerableSet.contains(_oracles, id); }

    function isRiskpool(uint256 id) public view returns (bool) { return EnumerableSet.contains(_riskpools, id); }

    function getPolicyFlow(uint256 productId) public view returns (address _policyFlow) {
        require(isProduct(productId), "ERROR:CCR-011:UNKNOWN_PRODUCT_ID");
        _policyFlow = _policyFlowByProductId[productId];
    }

    function _changeState(uint256 componentId, IComponent.ComponentState newState) internal {
        IComponent.ComponentState oldState = _componentState[componentId];

        _checkStateTransition(oldState, newState);
        _componentState[componentId] = newState;

        // log entry for successful component state change
        emit LogComponentStateChanged(componentId, oldState, newState);
    }

    function _checkStateTransition(
        IComponent.ComponentState oldState, 
        IComponent.ComponentState newState
    ) 
        internal 
        pure 
    {
        require(newState != oldState, 
            "ERROR:CCR-020:SOURCE_AND_TARGET_STATE_IDENTICAL");
        
        if (oldState == IComponent.ComponentState.Created) {
            require(newState == IComponent.ComponentState.Proposed, 
                "ERROR:CCR-021:CREATED_INVALID_TRANSITION");
        } else if (oldState == IComponent.ComponentState.Proposed) {
            require(newState == IComponent.ComponentState.Active 
                || newState == IComponent.ComponentState.Declined, 
                "ERROR:CCR-22:PROPOSED_INVALID_TRANSITION");
        } else if (oldState == IComponent.ComponentState.Declined) {
            revert("ERROR:CCR-023:DECLINED_IS_FINAL_STATE");
        } else if (oldState == IComponent.ComponentState.Active) {
            require(newState == IComponent.ComponentState.Paused 
                || newState == IComponent.ComponentState.Suspended, 
                "ERROR:CCR-024:ACTIVE_INVALID_TRANSITION");
        } else if (oldState == IComponent.ComponentState.Paused) {
            require(newState == IComponent.ComponentState.Active
                || newState == IComponent.ComponentState.Archived, 
                "ERROR:CCR-025:PAUSED_INVALID_TRANSITION");
        } else if (oldState == IComponent.ComponentState.Suspended) {
            require(newState == IComponent.ComponentState.Active
                || newState == IComponent.ComponentState.Archived, 
                "ERROR:CCR-026:SUSPENDED_INVALID_TRANSITION");
        } else {
            revert("ERROR:CCR-027:INITIAL_STATE_NOT_HANDLED");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IAccess.sol";
import "IRegistry.sol";

import "Initializable.sol";
import "Context.sol";

contract CoreController is
    Context,
    Initializable 
{
    IRegistry internal _registry;
    IAccess internal _access;

    constructor () {
        _disableInitializers();
    }

    modifier onlyInstanceOperator() {
        require(
            _registry.ensureSender(_msgSender(), "InstanceOperatorService"),
            "ERROR:CRC-001:NOT_INSTANCE_OPERATOR");
        _;
    }

    modifier onlyPolicyFlow(bytes32 module) {
        // Allow only from delegator
        require(
            address(this) == _getContractAddress(module),
            "ERROR:CRC-002:NOT_ON_STORAGE"
        );

        // Allow only ProductService (it delegates to PolicyFlow)
        require(
            _msgSender() == _getContractAddress("ProductService"),
            "ERROR:CRC-003:NOT_PRODUCT_SERVICE"
        );
        _;
    }

    function initialize(address registry) public initializer {
        _registry = IRegistry(registry);
        if (_getName() != "Access") { _access = IAccess(_getContractAddress("Access")); }
        
        _afterInitialize();
    }

    function _getName() internal virtual pure returns(bytes32) { return ""; }

    function _afterInitialize() internal virtual onlyInitializing {}

    function _getContractAddress(bytes32 contractName) internal view returns (address contractAddress) { 
        contractAddress = _registry.getContract(contractName);
        require(
            contractAddress != address(0),
            "ERROR:CRC-004:CONTRACT_NOT_REGISTERED"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IAccess {
    function getDefaultAdminRole() external view returns(bytes32 role);
    function getProductOwnerRole() external view returns(bytes32 role);
    function getOracleProviderRole() external view returns(bytes32 role);
    function getRiskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns(bool);

    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;
    function renounceRole(bytes32 role, address principal) external;
    
    function addRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRegistry {

    event LogContractRegistered(
        bytes32 release,
        bytes32 contractName,
        address contractAddress,
        bool isNew
    );

    event LogContractDeregistered(bytes32 release, bytes32 contractName);

    event LogReleasePrepared(bytes32 release);

    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external;

    function deregister(bytes32 _contractName) external;

    function prepareRelease(bytes32 _newRelease) external;

    function getContractInRelease(bytes32 _release, bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getContract(bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getRelease() external view returns (bytes32 _release);

    function ensureSender(address sender, bytes32 _contractName) external view returns(bool _senderMatches);

    function contracts() external view returns (uint256 _numberOfContracts);

    function contractName(uint256 idx) external view returns (bytes32 _contractName);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IRegistry.sol";

interface IComponent {

    enum ComponentType {
        Oracle,
        Product,
        Riskpool
    }

    enum ComponentState {
        Created,
        Proposed,
        Declined,
        Active,
        Paused,
        Suspended,
        Archived
    }

    event LogComponentCreated (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        address registryAddress);

    function setId(uint256 id) external;

    function getName() external view returns(bytes32);
    function getId() external view returns(uint256);
    function getType() external view returns(ComponentType);
    function getState() external view returns(ComponentState);
    function getOwner() external view returns(address);

    function isProduct() external view returns(bool);
    function isOracle() external view returns(bool);
    function isRiskpool() external view returns(bool);

    function getRegistry() external view returns(IRegistry);

    function proposalCallback() external;
    function approvalCallback() external; 
    function declineCallback() external;
    function suspendCallback() external;
    function resumeCallback() external;
    function pauseCallback() external;
    function unpauseCallback() external;
    function archiveCallback() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IOracle is IComponent {
    
    event LogOracleCreated (address oracleAddress);
    event LogOracleProposed (uint256 componentId);
    event LogOracleApproved (uint256 componentId);
    event LogOracleDeclined (uint256 componentId);
    
    function request(uint256 requestId, bytes calldata input) external;
    function cancel(uint256 requestId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IProduct is IComponent {

    event LogProductCreated (address productAddress);
    event LogProductProposed (uint256 componentId);
    event LogProductApproved (uint256 componentId);
    event LogProductDeclined (uint256 componentId);

    function getToken() external view returns(address token);
    function getPolicyFlow() external view returns(address policyFlow);
    function getRiskpoolId() external view returns(uint256 riskpoolId);

    function getApplicationDataStructure() external view returns(string memory dataStructure);
    function getClaimDataStructure() external view returns(string memory dataStructure);
    function getPayoutDataStructure() external view returns(string memory dataStructure);

    function riskPoolCapacityCallback(uint256 capacity) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";
import "IBundle.sol";
import "IPolicy.sol";

interface IRiskpool is IComponent {

    event LogRiskpoolCreated (address riskpoolAddress);
    event LogRiskpoolProposed (uint256 id);
    event LogRiskpoolApproved (uint256 id);
    event LogRiskpoolDeclined (uint256 id);

    event LogRiskpoolBundleCreated(uint256 bundleId, uint256 amount);
    event LogRiskpoolBundleMatchesPolicy(uint256 bundleId, bool isMatching);
    event LogRiskpoolCollateralLocked(bytes32 processId, uint256 collateralAmount, bool isSecured);

    event LogRiskpoolPremiumProcessed(bytes32 processId, uint256 amount);
    event LogRiskpoolPayoutProcessed(bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralReleased(bytes32 processId, uint256 collateralAmount);


    function createBundle(bytes memory filter, uint256 initialAmount) external returns(uint256 bundleId);
    function fundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);
    function defundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);

    function lockBundle(uint256 bundleId) external;
    function unlockBundle(uint256 bundleId) external;
    function closeBundle(uint256 bundleId) external;
    function burnBundle(uint256 bundleId) external;

    function collateralizePolicy(bytes32 processId, uint256 collateralAmount) external returns(bool isSecured);
    function processPolicyPremium(bytes32 processId, uint256 amount) external;
    function processPolicyPayout(bytes32 processId, uint256 amount) external;
    function releasePolicy(bytes32 processId) external;

    function getCollateralizationLevel() external view returns (uint256);
    function getFullCollateralizationLevel() external view returns (uint256);

    function bundleMatchesApplication(
        IBundle.Bundle memory bundle, 
        IPolicy.Application memory application
    ) 
        external view returns(bool isMatching);   
    
    function getFilterDataStructure() external view returns(string memory);

    function bundles() external view returns(uint256);
    function getBundle(uint256 idx) external view returns(IBundle.Bundle memory);

    function activeBundles() external view returns(uint256);
    function getActiveBundleId(uint256 idx) external view returns(uint256 bundleId);

    function getWallet() external view returns(address);
    function getErc20Token() external view returns(address);

    function getSumOfSumInsuredCap() external view returns (uint256);
    function getCapital() external view returns(uint256);
    function getTotalValueLocked() external view returns(uint256); 
    function getCapacity() external view returns(uint256); 
    function getBalance() external view returns(uint256); 

    function setMaximumNumberOfActiveBundles(uint256 maximumNumberOfActiveBundles) external; 
    function getMaximumNumberOfActiveBundles() external view returns(uint256 maximumNumberOfActiveBundles);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IBundle {

    event LogBundleCreated(
        uint256 bundleId, 
        uint256 riskpoolId, 
        address owner,
        BundleState state,
        uint256 amount
    );

    event LogBundleStateChanged(uint256 bundleId, BundleState oldState, BundleState newState);

    event LogBundleCapitalProvided(uint256 bundleId, address sender, uint256 amount, uint256 capacity);
    event LogBundleCapitalWithdrawn(uint256 bundleId, address recipient, uint256 amount, uint256 capacity);

    event LogBundlePolicyCollateralized(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);
    event LogBundlePayoutProcessed(uint256 bundleId, bytes32 processId, uint256 amount);
    event LogBundlePolicyReleased(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);

    enum BundleState {
        Active,
        Locked,
        Closed,
        Burned
    }

    struct Bundle {
        uint256 id;
        uint256 riskpoolId;
        uint256 tokenId;
        BundleState state;
        bytes filter; // required conditions for applications to be considered for collateralization by this bundle
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function create(address owner_, uint256 riskpoolId_, bytes calldata filter_, uint256 amount_) external returns(uint256 bundleId);
    function fund(uint256 bundleId, uint256 amount) external;
    function defund(uint256 bundleId, uint256 amount) external;

    function lock(uint256 bundleId) external;
    function unlock(uint256 bundleId) external;
    function close(uint256 bundleId) external;
    function burn(uint256 bundleId) external;

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 collateralAmount) external;
    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function releasePolicy(uint256 bundleId, bytes32 processId) external returns(uint256 collateralAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPolicy {

    // Events
    event LogMetadataCreated(
        address owner,
        bytes32 processId,
        uint256 productId, 
        PolicyFlowState state
    );

    event LogMetadataStateChanged(
        bytes32 processId, 
        PolicyFlowState state
    );

    event LogApplicationCreated(
        bytes32 processId, 
        uint256 premiumAmount, 
        uint256 sumInsuredAmount
    );

    event LogApplicationRevoked(bytes32 processId);
    event LogApplicationUnderwritten(bytes32 processId);
    event LogApplicationDeclined(bytes32 processId);

    event LogPolicyCreated(bytes32 processId);
    event LogPolicyExpired(bytes32 processId);
    event LogPolicyClosed(bytes32 processId);

    event LogPremiumCollected(bytes32 processId, uint256 amount);
    
    event LogApplicationSumInsuredAdjusted(bytes32 processId, uint256 sumInsuredAmountOld, uint256 sumInsuredAmount);
    event LogApplicationPremiumAdjusted(bytes32 processId, uint256 premiumAmountOld, uint256 premiumAmount);
    event LogPolicyPremiumAdjusted(bytes32 processId, uint256 premiumExpectedAmountOld, uint256 premiumExpectedAmount);

    event LogClaimCreated(bytes32 processId, uint256 claimId, uint256 claimAmount);
    event LogClaimConfirmed(bytes32 processId, uint256 claimId, uint256 confirmedAmount);
    event LogClaimDeclined(bytes32 processId, uint256 claimId);
    event LogClaimClosed(bytes32 processId, uint256 claimId);

    event LogPayoutCreated(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutId,
        uint256 amount
    );

    event LogPayoutProcessed(
        bytes32 processId, 
        uint256 payoutId
    );

    // States
    enum PolicyFlowState {Started, Active, Finished}
    enum ApplicationState {Applied, Revoked, Underwritten, Declined}
    enum PolicyState {Active, Expired, Closed}
    enum ClaimState {Applied, Confirmed, Declined, Closed}
    enum PayoutState {Expected, PaidOut}

    // Objects
    struct Metadata {
        address owner;
        uint256 productId;
        PolicyFlowState state;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Application {
        ApplicationState state;
        uint256 premiumAmount;
        uint256 sumInsuredAmount;
        bytes data; 
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Policy {
        PolicyState state;
        uint256 premiumExpectedAmount;
        uint256 premiumPaidAmount;
        uint256 claimsCount;
        uint256 openClaimsCount;
        uint256 payoutMaxAmount;
        uint256 payoutAmount;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Claim {
        ClaimState state;
        uint256 claimAmount;
        uint256 paidAmount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Payout {
        uint256 claimId;
        PayoutState state;
        uint256 amount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function createPolicyFlow(
        address owner,
        uint256 productId, 
        bytes calldata data
    ) external returns(bytes32 processId);

    function createApplication(
        bytes32 processId, 
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata data
    ) external;

    function revokeApplication(bytes32 processId) external;
    function underwriteApplication(bytes32 processId) external;
    function declineApplication(bytes32 processId) external;

    function collectPremium(bytes32 processId, uint256 amount) external;

    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) external;

    function createPolicy(bytes32 processId) external;
    function expirePolicy(bytes32 processId) external;
    function closePolicy(bytes32 processId) external;

    function createClaim(
        bytes32 processId, 
        uint256 claimAmount, 
        bytes calldata data
    ) external returns (uint256 claimId);

    function confirmClaim(
        bytes32 processId, 
        uint256 claimId, 
        uint256 confirmedAmount
    ) external;

    function declineClaim(bytes32 processId, uint256 claimId) external;
    function closeClaim(bytes32 processId, uint256 claimId) external;

    function createPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount,
        bytes calldata data
    ) external returns (uint256 payoutId);

    function processPayout(
        bytes32 processId,
        uint256 payoutId
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IComponentEvents {

    event LogComponentProposed (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        uint256 id);
    
    event LogComponentApproved (uint256 id);
    event LogComponentDeclined (uint256 id);

    event LogComponentSuspended (uint256 id);
    event LogComponentResumed (uint256 id);

    event LogComponentPaused (uint256 id);
    event LogComponentUnpaused (uint256 id);

    event LogComponentArchived (uint256 id);

    event LogComponentStateChanged (
        uint256 id, 
        IComponent.ComponentState stateOld, 
        IComponent.ComponentState stateNew);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "CoreController.sol";
import "ComponentController.sol";
import "IPolicy.sol";

contract PolicyController is 
    IPolicy, 
    CoreController
{
    // bytes32 public constant NAME = "PolicyController";

    // Metadata
    mapping(bytes32 /* processId */ => Metadata) public metadata;

    // Applications
    mapping(bytes32 /* processId */ => Application) public applications;

    // Policies
    mapping(bytes32 /* processId */ => Policy) public policies;

    // Claims
    mapping(bytes32 /* processId */ => mapping(uint256 /* claimId */ => Claim)) public claims;

    // Payouts
    mapping(bytes32 /* processId */ => mapping(uint256 /* payoutId */ => Payout)) public payouts;
    mapping(bytes32 /* processId */ => uint256) public payoutCount;

    // counter for assigned processIds, used to ensure unique processIds
    uint256 private _assigendProcessIds;

    ComponentController private _component;

    function _afterInitialize() internal override onlyInitializing {
        _component = ComponentController(_getContractAddress("Component"));
    }

    /* Metadata */
    function createPolicyFlow(
        address owner,
        uint256 productId,
        bytes calldata data
    )
        external override
        onlyPolicyFlow("Policy")
        returns(bytes32 processId)
    {
        require(owner != address(0), "ERROR:POL-001:INVALID_OWNER");

        require(_component.isProduct(productId), "ERROR:POL-002:INVALID_PRODUCT");
        require(_component.getComponentState(productId) == IComponent.ComponentState.Active, "ERROR:POL-003:PRODUCT_NOT_ACTIVE");
        
        processId = _generateNextProcessId();
        Metadata storage meta = metadata[processId];
        require(meta.createdAt == 0, "ERROR:POC-004:METADATA_ALREADY_EXISTS");

        meta.owner = owner;
        meta.productId = productId;
        meta.state = PolicyFlowState.Started;
        meta.data = data;
        meta.createdAt = block.timestamp; // solhint-disable-line
        meta.updatedAt = block.timestamp; // solhint-disable-line

        emit LogMetadataCreated(owner, processId, productId, PolicyFlowState.Started);
    }

    /* Application */
    function createApplication(
        bytes32 processId, 
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata data
    )
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-010:METADATA_DOES_NOT_EXIST");

        Application storage application = applications[processId];
        require(application.createdAt == 0, "ERROR:POC-011:APPLICATION_ALREADY_EXISTS");

        require(premiumAmount > 0, "ERROR:POC-012:PREMIUM_AMOUNT_ZERO");
        require(sumInsuredAmount > premiumAmount, "ERROR:POC-013:SUM_INSURED_AMOUNT_TOO_SMALL");

        application.state = ApplicationState.Applied;
        application.premiumAmount = premiumAmount;
        application.sumInsuredAmount = sumInsuredAmount;
        application.data = data;
        application.createdAt = block.timestamp; // solhint-disable-line
        application.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Active;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogApplicationCreated(processId, premiumAmount, sumInsuredAmount);
    }

    function collectPremium(bytes32 processId, uint256 amount) 
        external override
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-110:POLICY_DOES_NOT_EXIST");
        require(policy.premiumPaidAmount + amount <= policy.premiumExpectedAmount, "ERROR:POC-111:AMOUNT_TOO_BIG");

        policy.premiumPaidAmount += amount;
        policy.updatedAt = block.timestamp; // solhint-disable-line
    
        emit LogPremiumCollected(processId, amount);
    }
    
    function revokeApplication(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-014:METADATA_DOES_NOT_EXIST");

        Application storage application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-015:APPLICATION_DOES_NOT_EXIST");
        require(application.state == ApplicationState.Applied, "ERROR:POC-016:APPLICATION_STATE_INVALID");

        application.state = ApplicationState.Revoked;
        application.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Finished;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogApplicationRevoked(processId);
    }

    function underwriteApplication(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Application storage application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-017:APPLICATION_DOES_NOT_EXIST");
        require(application.state == ApplicationState.Applied, "ERROR:POC-018:APPLICATION_STATE_INVALID");

        application.state = ApplicationState.Underwritten;
        application.updatedAt = block.timestamp; // solhint-disable-line

        emit LogApplicationUnderwritten(processId);
    }

    function declineApplication(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-019:METADATA_DOES_NOT_EXIST");

        Application storage application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-020:APPLICATION_DOES_NOT_EXIST");
        require(application.state == ApplicationState.Applied, "ERROR:POC-021:APPLICATION_STATE_INVALID");

        application.state = ApplicationState.Declined;
        application.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Finished;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogApplicationDeclined(processId);
    }

    /* Policy */
    function createPolicy(bytes32 processId) 
        external override 
        onlyPolicyFlow("Policy")
    {
        Application memory application = applications[processId];
        require(application.createdAt > 0 && application.state == ApplicationState.Underwritten, "ERROR:POC-022:APPLICATION_ACCESS_INVALID");

        Policy storage policy = policies[processId];
        require(policy.createdAt == 0, "ERROR:POC-023:POLICY_ALREADY_EXISTS");

        policy.state = PolicyState.Active;
        policy.premiumExpectedAmount = application.premiumAmount;
        policy.payoutMaxAmount = application.sumInsuredAmount;
        policy.createdAt = block.timestamp; // solhint-disable-line
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPolicyCreated(processId);
    }

    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    )
        external override
        onlyPolicyFlow("Policy")
    {
        Application storage application = applications[processId];
        require(
            application.createdAt > 0 
            && application.state == ApplicationState.Underwritten, 
            "ERROR:POC-024:APPLICATION_ACCESS_INVALID");

        require(
            sumInsuredAmount <= application.sumInsuredAmount, 
            "ERROR:POC-026:APPLICATION_SUM_INSURED_INCREASE_INVALID");

        Policy storage policy = policies[processId];
        require(
            policy.createdAt > 0 
            && policy.state == IPolicy.PolicyState.Active, 
            "ERROR:POC-027:POLICY_ACCESS_INVALID");
        
        require(
            expectedPremiumAmount > 0 
            && expectedPremiumAmount >= policy.premiumPaidAmount
            && expectedPremiumAmount < sumInsuredAmount, 
            "ERROR:POC-025:APPLICATION_PREMIUM_INVALID");

        if (sumInsuredAmount != application.sumInsuredAmount) {
            emit LogApplicationSumInsuredAdjusted(processId, application.sumInsuredAmount, sumInsuredAmount);
            application.sumInsuredAmount = sumInsuredAmount;
            application.updatedAt = block.timestamp; // solhint-disable-line

            policy.payoutMaxAmount = sumInsuredAmount;
            policy.updatedAt = block.timestamp; // solhint-disable-line
        }

        if (expectedPremiumAmount != application.premiumAmount) {
            emit LogApplicationPremiumAdjusted(processId, application.premiumAmount, expectedPremiumAmount);
            application.premiumAmount = expectedPremiumAmount;
            application.updatedAt = block.timestamp; // solhint-disable-line

            emit LogPolicyPremiumAdjusted(processId, policy.premiumExpectedAmount, expectedPremiumAmount);
            policy.premiumExpectedAmount = expectedPremiumAmount;
            policy.updatedAt = block.timestamp; // solhint-disable-line
        }
    }

    function expirePolicy(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-028:POLICY_DOES_NOT_EXIST");
        require(policy.state == PolicyState.Active, "ERROR:POC-029:APPLICATION_STATE_INVALID");

        policy.state = PolicyState.Expired;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPolicyExpired(processId);
    }

    function closePolicy(bytes32 processId)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[processId];
        require(meta.createdAt > 0, "ERROR:POC-030:METADATA_DOES_NOT_EXIST");

        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-031:POLICY_DOES_NOT_EXIST");
        require(policy.state == PolicyState.Expired, "ERROR:POC-032:POLICY_STATE_INVALID");
        require(policy.openClaimsCount == 0, "ERROR:POC-033:POLICY_HAS_OPEN_CLAIMS");

        policy.state = PolicyState.Closed;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        meta.state = PolicyFlowState.Finished;
        meta.updatedAt = block.timestamp; // solhint-disable-line
        emit LogMetadataStateChanged(processId, meta.state);

        emit LogPolicyClosed(processId);
    }

    /* Claim */
    function createClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes calldata data
    )
        external override
        onlyPolicyFlow("Policy")
        returns (uint256 claimId)
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-040:POLICY_DOES_NOT_EXIST");
        require(policy.state == IPolicy.PolicyState.Active, "ERROR:POC-041:POLICY_NOT_ACTIVE");
        // no validation of claimAmount > 0 here to explicitly allow claims with amount 0. This can be useful for parametric insurance 
        // to have proof that the claim calculation was executed without entitlement to payment.
        require(policy.payoutAmount + claimAmount <= policy.payoutMaxAmount, "ERROR:POC-042:CLAIM_AMOUNT_EXCEEDS_MAX_PAYOUT");

        claimId = policy.claimsCount;
        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt == 0, "ERROR:POC-043:CLAIM_ALREADY_EXISTS");

        claim.state = ClaimState.Applied;
        claim.claimAmount = claimAmount;
        claim.data = data;
        claim.createdAt = block.timestamp; // solhint-disable-line
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.claimsCount++;
        policy.openClaimsCount++;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimCreated(processId, claimId, claimAmount);
    }

    function confirmClaim(
        bytes32 processId,
        uint256 claimId,
        uint256 confirmedAmount
    ) 
        external override
        onlyPolicyFlow("Policy") 
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-050:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-051:POLICY_WITHOUT_OPEN_CLAIMS");
        // no validation of claimAmount > 0 here as is it possible to have claims with amount 0 (see createClaim()). 
        require(policy.payoutAmount + confirmedAmount <= policy.payoutMaxAmount, "ERROR:POC-052:PAYOUT_MAX_AMOUNT_EXCEEDED");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-053:CLAIM_DOES_NOT_EXIST");
        require(claim.state == ClaimState.Applied, "ERROR:POC-054:CLAIM_STATE_INVALID");

        claim.state = ClaimState.Confirmed;
        claim.claimAmount = confirmedAmount;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.payoutAmount += confirmedAmount;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimConfirmed(processId, claimId, confirmedAmount);
    }

    function declineClaim(bytes32 processId, uint256 claimId)
        external override
        onlyPolicyFlow("Policy") 
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-060:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-061:POLICY_WITHOUT_OPEN_CLAIMS");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-062:CLAIM_DOES_NOT_EXIST");
        require(claim.state == ClaimState.Applied, "ERROR:POC-063:CLAIM_STATE_INVALID");

        claim.state = ClaimState.Declined;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimDeclined(processId, claimId);
    }

    function closeClaim(bytes32 processId, uint256 claimId)
        external override
        onlyPolicyFlow("Policy") 
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-070:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-071:POLICY_WITHOUT_OPEN_CLAIMS");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-072:CLAIM_DOES_NOT_EXIST");
        require(
            claim.state == ClaimState.Confirmed 
            || claim.state == ClaimState.Declined, 
            "ERROR:POC-073:CLAIM_STATE_INVALID");

        require(
            (claim.state == ClaimState.Confirmed && claim.claimAmount == claim.paidAmount) 
            || (claim.state == ClaimState.Declined), 
            "ERROR:POC-074:CLAIM_WITH_UNPAID_PAYOUTS"
        );

        claim.state = ClaimState.Closed;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        policy.openClaimsCount--;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogClaimClosed(processId, claimId);
    }

    /* Payout */
    function createPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount,
        bytes calldata data
    )
        external override 
        onlyPolicyFlow("Policy") 
        returns (uint256 payoutId)
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-080:POLICY_DOES_NOT_EXIST");

        Claim storage claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-081:CLAIM_DOES_NOT_EXIST");
        require(claim.state == IPolicy.ClaimState.Confirmed, "ERROR:POC-082:CLAIM_NOT_CONFIRMED");
        require(payoutAmount > 0, "ERROR:POC-083:PAYOUT_AMOUNT_ZERO_INVALID");
        require(
            claim.paidAmount + payoutAmount <= claim.claimAmount,
            "ERROR:POC-084:PAYOUT_AMOUNT_TOO_BIG"
        );

        payoutId = payoutCount[processId];
        Payout storage payout = payouts[processId][payoutId];
        require(payout.createdAt == 0, "ERROR:POC-085:PAYOUT_ALREADY_EXISTS");

        payout.claimId = claimId;
        payout.amount = payoutAmount;
        payout.data = data;
        payout.state = PayoutState.Expected;
        payout.createdAt = block.timestamp; // solhint-disable-line
        payout.updatedAt = block.timestamp; // solhint-disable-line

        payoutCount[processId]++;
        policy.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPayoutCreated(processId, claimId, payoutId, payoutAmount);
    }

    function processPayout(
        bytes32 processId,
        uint256 payoutId
    )
        external override 
        onlyPolicyFlow("Policy")
    {
        Policy storage policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-090:POLICY_DOES_NOT_EXIST");
        require(policy.openClaimsCount > 0, "ERROR:POC-091:POLICY_WITHOUT_OPEN_CLAIMS");

        Payout storage payout = payouts[processId][payoutId];
        require(payout.createdAt > 0, "ERROR:POC-092:PAYOUT_DOES_NOT_EXIST");
        require(payout.state == PayoutState.Expected, "ERROR:POC-093:PAYOUT_ALREADY_PAIDOUT");

        payout.state = IPolicy.PayoutState.PaidOut;
        payout.updatedAt = block.timestamp; // solhint-disable-line

        emit LogPayoutProcessed(processId, payoutId);

        Claim storage claim = claims[processId][payout.claimId];
        claim.paidAmount += payout.amount;
        claim.updatedAt = block.timestamp; // solhint-disable-line

        // check if claim can be closed
        if (claim.claimAmount == claim.paidAmount) {
            claim.state = IPolicy.ClaimState.Closed;

            policy.openClaimsCount -= 1;
            policy.updatedAt = block.timestamp; // solhint-disable-line

            emit LogClaimClosed(processId, payout.claimId);
        }
    }

    function getMetadata(bytes32 processId)
        public
        view
        returns (IPolicy.Metadata memory _metadata)
    {
        _metadata = metadata[processId];
        require(_metadata.createdAt > 0,  "ERROR:POC-100:METADATA_DOES_NOT_EXIST");
    }

    function getApplication(bytes32 processId)
        public
        view
        returns (IPolicy.Application memory application)
    {
        application = applications[processId];
        require(application.createdAt > 0, "ERROR:POC-101:APPLICATION_DOES_NOT_EXIST");        
    }

    function getNumberOfClaims(bytes32 processId) external view returns(uint256 numberOfClaims) {
        numberOfClaims = getPolicy(processId).claimsCount;
    }
    
    function getNumberOfPayouts(bytes32 processId) external view returns(uint256 numberOfPayouts) {
        numberOfPayouts = payoutCount[processId];
    }

    function getPolicy(bytes32 processId)
        public
        view
        returns (IPolicy.Policy memory policy)
    {
        policy = policies[processId];
        require(policy.createdAt > 0, "ERROR:POC-102:POLICY_DOES_NOT_EXIST");        
    }

    function getClaim(bytes32 processId, uint256 claimId)
        public
        view
        returns (IPolicy.Claim memory claim)
    {
        claim = claims[processId][claimId];
        require(claim.createdAt > 0, "ERROR:POC-103:CLAIM_DOES_NOT_EXIST");        
    }

    function getPayout(bytes32 processId, uint256 payoutId)
        public
        view
        returns (IPolicy.Payout memory payout)
    {
        payout = payouts[processId][payoutId];
        require(payout.createdAt > 0, "ERROR:POC-104:PAYOUT_DOES_NOT_EXIST");        
    }

    function processIds() external view returns (uint256) {
        return _assigendProcessIds;
    }

    function _generateNextProcessId() private returns(bytes32 processId) {
        _assigendProcessIds++;

        processId = keccak256(
            abi.encodePacked(
                block.chainid, 
                address(_registry),
                _assigendProcessIds
            )
        );
    } 
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "PolicyController.sol";
import "CoreController.sol";
import "BundleToken.sol";

import "IProduct.sol";
import "IBundle.sol";
import "PoolController.sol";


contract BundleController is 
    IBundle,
    CoreController
{

    PolicyController private _policy;
    BundleToken private _token; 

    mapping(uint256 /* bundleId */ => Bundle /* Bundle */) private _bundles;
    mapping(uint256 /* bundleId */ => uint256 /* activePolicyCount */) private _activePolicies;
    mapping(uint256 /* bundleId */ => mapping(bytes32 /* processId */ => uint256 /* lockedCapitalAmount */)) private _valueLockedPerPolicy;
    mapping(uint256 /* riskpoolId */ => uint256 /* numberOfUnburntBundles */) private _unburntBundlesForRiskpoolId;
    

    uint256 private _bundleCount;

    modifier onlyRiskpoolService() {
        require(
            _msgSender() == _getContractAddress("RiskpoolService"),
            "ERROR:BUC-001:NOT_RISKPOOL_SERVICE"
        );
        _;
    }

    modifier onlyFundableBundle(uint256 bundleId) {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-002:BUNDLE_DOES_NOT_EXIST");
        require(
            bundle.state != IBundle.BundleState.Burned 
            && bundle.state != IBundle.BundleState.Closed, "ERROR:BUC-003:BUNDLE_BURNED_OR_CLOSED"
        );
        _;
    }

    function _afterInitialize() internal override onlyInitializing {
        _policy = PolicyController(_getContractAddress("Policy"));
        _token = BundleToken(_getContractAddress("BundleToken"));
    }

    function create(address owner_, uint riskpoolId_, bytes calldata filter_, uint256 amount_) 
        external override
        onlyRiskpoolService
        returns(uint256 bundleId)
    {   
        // will start with bundleId 1.
        // this helps in maps where a bundleId equals a non-existing entry
        bundleId = _bundleCount + 1;
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt == 0, "ERROR:BUC-010:BUNDLE_ALREADY_EXISTS");

        // mint corresponding nft with bundleId as nft
        uint256 tokenId = _token.mint(bundleId, owner_);

        bundle.id = bundleId;
        bundle.tokenId = tokenId;
        bundle.riskpoolId = riskpoolId_;
        bundle.state = BundleState.Active;
        bundle.filter = filter_;
        bundle.capital = amount_;
        bundle.balance = amount_;
        bundle.createdAt = block.timestamp;
        bundle.updatedAt = block.timestamp;

        // update bundle count
        _bundleCount++;
        _unburntBundlesForRiskpoolId[riskpoolId_]++;

        emit LogBundleCreated(bundle.id, riskpoolId_, owner_, bundle.state, bundle.capital);
    }


    function fund(uint256 bundleId, uint256 amount)
        external override 
        onlyRiskpoolService
    {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-011:BUNDLE_DOES_NOT_EXIST");
        require(bundle.state != IBundle.BundleState.Closed, "ERROR:BUC-012:BUNDLE_CLOSED");

        bundle.capital += amount;
        bundle.balance += amount;
        bundle.updatedAt = block.timestamp;

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundleCapitalProvided(bundleId, _msgSender(), amount, capacityAmount);
    }


    function defund(uint256 bundleId, uint256 amount) 
        external override 
        onlyRiskpoolService
    {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-013:BUNDLE_DOES_NOT_EXIST");
        require(
            bundle.capital >= bundle.lockedCapital + amount
            || (bundle.lockedCapital == 0 && bundle.balance >= amount),
            "ERROR:BUC-014:CAPACITY_OR_BALANCE_TOO_LOW"
        );

        if (bundle.capital >= amount) { bundle.capital -= amount; } 
        else                          { bundle.capital = 0; }

        bundle.balance -= amount;
        bundle.updatedAt = block.timestamp;

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundleCapitalWithdrawn(bundleId, _msgSender(), amount, capacityAmount);
    }

    function lock(uint256 bundleId)
        external override
        onlyRiskpoolService
    {
        _changeState(bundleId, BundleState.Locked);
    }

    function unlock(uint256 bundleId)
        external override
        onlyRiskpoolService
    {
        _changeState(bundleId, BundleState.Active);
    }

    function close(uint256 bundleId)
        external override
        onlyRiskpoolService
    {
        require(_activePolicies[bundleId] == 0, "ERROR:BUC-015:BUNDLE_WITH_ACTIVE_POLICIES");
        _changeState(bundleId, BundleState.Closed);
    }

    function burn(uint256 bundleId)    
        external override
        onlyRiskpoolService
    {
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.state == BundleState.Closed, "ERROR:BUC-016:BUNDLE_NOT_CLOSED");
        require(bundle.balance == 0, "ERROR:BUC-017:BUNDLE_HAS_BALANCE");

        // burn corresponding nft -> as a result bundle looses its owner
        _token.burn(bundleId);
        _unburntBundlesForRiskpoolId[bundle.riskpoolId] -= 1;

        _changeState(bundleId, BundleState.Burned);
    }

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 amount)
        external override 
        onlyRiskpoolService
    {
        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.riskpoolId == _getPoolController().getRiskPoolForProduct(metadata.productId), "ERROR:BUC-019:BUNDLE_NOT_IN_RISKPOOL");
        require(bundle.createdAt > 0, "ERROR:BUC-020:BUNDLE_DOES_NOT_EXIST");
        require(bundle.state == IBundle.BundleState.Active, "ERROR:BUC-021:BUNDLE_NOT_ACTIVE");        
        require(bundle.capital >= bundle.lockedCapital + amount, "ERROR:BUC-022:CAPACITY_TOO_LOW");

        // might need to be added in a future relase
        require(_valueLockedPerPolicy[bundleId][processId] == 0, "ERROR:BUC-023:INCREMENTAL_COLLATERALIZATION_NOT_IMPLEMENTED");

        bundle.lockedCapital += amount;
        bundle.updatedAt = block.timestamp;

        _activePolicies[bundleId] += 1;
        _valueLockedPerPolicy[bundleId][processId] = amount;

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundlePolicyCollateralized(bundleId, processId, amount, capacityAmount);
    }


    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount)
        external override
        onlyRiskpoolService
        onlyFundableBundle(bundleId)
    {
        IPolicy.Policy memory policy = _policy.getPolicy(processId);
        require(
            policy.state != IPolicy.PolicyState.Closed,
            "ERROR:POL-030:POLICY_STATE_INVALID"
        );

        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-031:BUNDLE_DOES_NOT_EXIST");
        
        bundle.balance += amount;
        bundle.updatedAt = block.timestamp; // solhint-disable-line
    }


    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) 
        external override 
        onlyRiskpoolService
    {
        IPolicy.Policy memory policy = _policy.getPolicy(processId);
        require(
            policy.state != IPolicy.PolicyState.Closed,
            "ERROR:POL-040:POLICY_STATE_INVALID"
        );

        // check there are policies and there is sufficient locked capital for policy
        require(_activePolicies[bundleId] > 0, "ERROR:BUC-041:NO_ACTIVE_POLICIES_FOR_BUNDLE");
        require(_valueLockedPerPolicy[bundleId][processId] >= amount, "ERROR:BUC-042:COLLATERAL_INSUFFICIENT_FOR_POLICY");

        // make sure bundle exists and is not yet closed
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-043:BUNDLE_DOES_NOT_EXIST");
        require(
            bundle.state == IBundle.BundleState.Active
            || bundle.state == IBundle.BundleState.Locked, 
            "ERROR:BUC-044:BUNDLE_STATE_INVALID");
        require(bundle.capital >= amount, "ERROR:BUC-045:CAPITAL_TOO_LOW");
        require(bundle.lockedCapital >= amount, "ERROR:BUC-046:LOCKED_CAPITAL_TOO_LOW");
        require(bundle.balance >= amount, "ERROR:BUC-047:BALANCE_TOO_LOW");

        _valueLockedPerPolicy[bundleId][processId] -= amount;
        bundle.capital -= amount;
        bundle.lockedCapital -= amount;
        bundle.balance -= amount;
        bundle.updatedAt = block.timestamp; // solhint-disable-line

        emit LogBundlePayoutProcessed(bundleId, processId, amount);
    }


    function releasePolicy(uint256 bundleId, bytes32 processId) 
        external override 
        onlyRiskpoolService
        returns(uint256 remainingCollateralAmount)
    {
        IPolicy.Policy memory policy = _policy.getPolicy(processId);
        require(
            policy.state == IPolicy.PolicyState.Closed,
            "ERROR:POL-050:POLICY_STATE_INVALID"
        );

        // make sure bundle exists and is not yet closed
        Bundle storage bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-051:BUNDLE_DOES_NOT_EXIST");
        require(_activePolicies[bundleId] > 0, "ERROR:BUC-052:NO_ACTIVE_POLICIES_FOR_BUNDLE");

        uint256 lockedForPolicyAmount = _valueLockedPerPolicy[bundleId][processId];
        // this should never ever fail ...
        require(
            bundle.lockedCapital >= lockedForPolicyAmount,
            "PANIC:BUC-053:UNLOCK_CAPITAL_TOO_BIG"
        );

        // policy no longer relevant for bundle
        _activePolicies[bundleId] -= 1;
        delete _valueLockedPerPolicy[bundleId][processId];

        // update bundle capital
        bundle.lockedCapital -= lockedForPolicyAmount;
        bundle.updatedAt = block.timestamp; // solhint-disable-line

        uint256 capacityAmount = bundle.capital - bundle.lockedCapital;
        emit LogBundlePolicyReleased(bundleId, processId, lockedForPolicyAmount, capacityAmount);
    }

    function getOwner(uint256 bundleId) public view returns(address) { 
        uint256 tokenId = getBundle(bundleId).tokenId;
        return _token.ownerOf(tokenId); 
    }

    function getState(uint256 bundleId) public view returns(BundleState) {
        return getBundle(bundleId).state;   
    }

    function getFilter(uint256 bundleId) public view returns(bytes memory) {
        return getBundle(bundleId).filter;
    }   

    function getCapacity(uint256 bundleId) public view returns(uint256) {
        Bundle memory bundle = getBundle(bundleId);
        return bundle.capital - bundle.lockedCapital;
    }

    function getTotalValueLocked(uint256 bundleId) public view returns(uint256) {
        return getBundle(bundleId).lockedCapital;   
    }

    function getBalance(uint256 bundleId) public view returns(uint256) {
        return getBundle(bundleId).balance;   
    }

    function getToken() external view returns(BundleToken) {
        return _token;
    }

    function getBundle(uint256 bundleId) public view returns(Bundle memory) {
        Bundle memory bundle = _bundles[bundleId];
        require(bundle.createdAt > 0, "ERROR:BUC-060:BUNDLE_DOES_NOT_EXIST");
        return bundle;
    }

    function bundles() public view returns(uint256) {
        return _bundleCount;
    }

    function unburntBundles(uint256 riskpoolId) external view returns(uint256) {
        return _unburntBundlesForRiskpoolId[riskpoolId];
    }

    function _getPoolController() internal view returns (PoolController _poolController) {
        _poolController = PoolController(_getContractAddress("Pool"));
    }

    function _changeState(uint256 bundleId, BundleState newState) internal {
        BundleState oldState = getState(bundleId);

        _checkStateTransition(oldState, newState);
        _setState(bundleId, newState);

        // log entry for successful state change
        emit LogBundleStateChanged(bundleId, oldState, newState);
    }

    function _setState(uint256 bundleId, BundleState newState) internal {
        _bundles[bundleId].state = newState;
        _bundles[bundleId].updatedAt = block.timestamp;
    }

    function _checkStateTransition(BundleState oldState, BundleState newState) 
        internal 
        pure 
    {
        if (oldState == BundleState.Active) {
            require(
                newState == BundleState.Locked || newState == BundleState.Closed, 
                "ERROR:BUC-070:ACTIVE_INVALID_TRANSITION"
            );
        } else if (oldState == BundleState.Locked) {
            require(
                newState == BundleState.Active || newState == BundleState.Closed, 
                "ERROR:BUC-071:LOCKED_INVALID_TRANSITION"
            );
        } else if (oldState == BundleState.Closed) {
            require(
                newState == BundleState.Burned, 
                "ERROR:BUC-072:CLOSED_INVALID_TRANSITION"
            );
        } else if (oldState == BundleState.Burned) {
            revert("ERROR:BUC-073:BURNED_IS_FINAL_STATE");
        } else {
            revert("ERROR:BOC-074:INITIAL_STATE_NOT_HANDLED");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "Ownable.sol";
import "ERC721.sol";

import "IBundleToken.sol";

contract BundleToken is 
    IBundleToken,
    ERC721,
    Ownable
{
    string public constant NAME = "GIF Bundle Token";
    string public constant SYMBOL = "BTK";

    mapping(uint256 /** tokenId */ => uint256 /** bundleId */) public bundleIdForTokenId;
    address private _bundleModule;
    uint256 private _totalSupply;

    modifier onlyBundleModule() {
        require(_bundleModule != address(0), "ERROR:BTK-001:NOT_INITIALIZED");
        require(_msgSender() == _bundleModule, "ERROR:BTK-002:NOT_BUNDLE_MODULE");
        _;
    }

    constructor() ERC721(NAME, SYMBOL) Ownable() { }

    function setBundleModule(address bundleModule)
        external
    {
        require(_bundleModule == address(0), "ERROR:BTK-003:BUNDLE_MODULE_ALREADY_DEFINED");
        require(bundleModule != address(0), "ERROR:BTK-004:INVALID_BUNDLE_MODULE_ADDRESS");
        _bundleModule = bundleModule;
    }


    function mint(uint256 bundleId, address to) 
        external
        onlyBundleModule
        returns(uint256 tokenId)
    {
        _totalSupply++;
        tokenId = _totalSupply;
        bundleIdForTokenId[tokenId] = bundleId;        
        
        _safeMint(to, tokenId);
        
        emit LogBundleTokenMinted(bundleId, tokenId, to);           
    }


    function burn(uint256 tokenId) 
        external
        onlyBundleModule
    {
        require(_exists(tokenId), "ERROR:BTK-005:TOKEN_ID_INVALID");        
        _burn(tokenId);
        
        emit LogBundleTokenBurned(bundleIdForTokenId[tokenId], tokenId);   
    }

    function burned(uint tokenId) 
        external override
        view 
        returns(bool isBurned)
    {
        isBurned = tokenId <= _totalSupply && !_exists(tokenId);
    }

    function getBundleId(uint256 tokenId) external override view returns(uint256) { return bundleIdForTokenId[tokenId]; }
    function getBundleModuleAddress() external view returns(address) { return _bundleModule; }

    function exists(uint256 tokenId) external override view returns(bool) { return tokenId <= _totalSupply; }
    function totalSupply() external override view returns(uint256 tokenCount) { return _totalSupply; }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IERC721.sol";

interface IBundleToken is
    IERC721
{
    event LogBundleTokenMinted(uint256 bundleId, uint256 tokenId, address tokenOwner);
    event LogBundleTokenBurned(uint256 bundleId, uint256 tokenId);   

    function burned(uint tokenId) external view returns(bool isBurned);
    function exists(uint256 tokenId) external view returns(bool doesExist);
    function getBundleId(uint256 tokenId) external view returns(uint256 bundleId);
    function totalSupply() external view returns(uint256 tokenCount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "ComponentController.sol";
import "PolicyController.sol";
import "BundleController.sol";
import "CoreController.sol";

import "IPool.sol";
import "IComponent.sol";
import "IRiskpool.sol";


import "EnumerableSet.sol";

contract PoolController is
    IPool,
    CoreController
{

    using EnumerableSet for EnumerableSet.UintSet;

    // used for representation of collateralization
    // collateralization between 0 and 1 (1=100%) 
    // value might be larger when overcollateralization
    uint256 public constant FULL_COLLATERALIZATION_LEVEL = 10**18;

    // upper limit for overcollateralization at 200% 
    uint256 public constant COLLATERALIZATION_LEVEL_CAP = 2 * FULL_COLLATERALIZATION_LEVEL;

    uint256 public constant DEFAULT_MAX_NUMBER_OF_ACTIVE_BUNDLES = 1;

    mapping(bytes32 /* processId */ => uint256 /* collateralAmount*/ ) private _collateralAmount;

    mapping(uint256 /* productId */ => uint256 /* riskpoolId */) private _riskpoolIdForProductId;

    mapping(uint256 /* riskpoolId */ => IPool.Pool)  private _riskpools;

    mapping(uint256 /* riskpoolId */ => uint256 /* maxmimumNumberOfActiveBundles */) private _maxmimumNumberOfActiveBundlesForRiskpoolId;

    mapping(uint256 /* riskpoolId */ => EnumerableSet.UintSet /* active bundle id set */) private _activeBundleIdsForRiskpoolId;
    
    uint256 [] private _riskpoolIds;

    ComponentController private _component;
    PolicyController private _policy;
    BundleController private _bundle;

    modifier onlyInstanceOperatorService() {
        require(
            _msgSender() == _getContractAddress("InstanceOperatorService"),
            "ERROR:POL-001:NOT_INSTANCE_OPERATOR"
        );
        _;
    }

    modifier onlyRiskpoolService() {
        require(
            _msgSender() == _getContractAddress("RiskpoolService"),
            "ERROR:POL-002:NOT_RISKPOOL_SERVICE"
        );
        _;
    }

    modifier onlyTreasury() {
        require(
            _msgSender() == _getContractAddress("Treasury"),
            "ERROR:POL-003:NOT_TREASURY"
        );
        _;
    }

    function _afterInitialize() internal override onlyInitializing {
        _component = ComponentController(_getContractAddress("Component"));
        _policy = PolicyController(_getContractAddress("Policy"));
        _bundle = BundleController(_getContractAddress("Bundle"));
    }


    function registerRiskpool(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token,
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    )
        external override
        onlyRiskpoolService
    {
        IPool.Pool storage pool = _riskpools[riskpoolId];
        _riskpoolIds.push(riskpoolId);
        _maxmimumNumberOfActiveBundlesForRiskpoolId[riskpoolId] = DEFAULT_MAX_NUMBER_OF_ACTIVE_BUNDLES;
        
        require(pool.createdAt == 0, "ERROR:POL-004:RISKPOOL_ALREADY_REGISTERED");

        require(wallet != address(0), "ERROR:POL-005:WALLET_ADDRESS_ZERO");
        require(erc20Token != address(0), "ERROR:POL-006:ERC20_ADDRESS_ZERO");
        require(collateralizationLevel <= COLLATERALIZATION_LEVEL_CAP, "ERROR:POL-007:COLLATERALIZATION_lEVEl_TOO_HIGH");
        require(sumOfSumInsuredCap > 0, "ERROR:POL-008:SUM_OF_SUM_INSURED_CAP_ZERO");

        pool.id = riskpoolId; 
        pool.wallet = wallet; 
        pool.erc20Token = erc20Token; 
        pool.collateralizationLevel = collateralizationLevel;
        pool.sumOfSumInsuredCap = sumOfSumInsuredCap;

        pool.sumOfSumInsuredAtRisk = 0;
        pool.capital = 0;
        pool.lockedCapital = 0;
        pool.balance = 0;

        pool.createdAt = block.timestamp;
        pool.updatedAt = block.timestamp;

        emit LogRiskpoolRegistered(riskpoolId, wallet, erc20Token, collateralizationLevel, sumOfSumInsuredCap);
    }

    function setRiskpoolForProduct(uint256 productId, uint256 riskpoolId) 
        external override
        onlyInstanceOperatorService
    {
        require(_component.isProduct(productId), "ERROR:POL-010:NOT_PRODUCT");
        require(_component.isRiskpool(riskpoolId), "ERROR:POL-011:NOT_RISKPOOL");
        require(_riskpoolIdForProductId[productId] == 0, "ERROR:POL-012:RISKPOOL_ALREADY_SET");
        
        _riskpoolIdForProductId[productId] = riskpoolId;
    }

    function fund(uint256 riskpoolId, uint256 amount) 
        external
        onlyRiskpoolService
    {
        IPool.Pool storage pool = _riskpools[riskpoolId];
        pool.capital += amount;
        pool.balance += amount;
        pool.updatedAt = block.timestamp;
    }

    function defund(uint256 riskpoolId, uint256 amount) 
        external
        onlyRiskpoolService
    {
        IPool.Pool storage pool = _riskpools[riskpoolId];

        if (pool.capital >= amount) { pool.capital -= amount; }
        else                        { pool.capital = 0; }

        pool.balance -= amount;
        pool.updatedAt = block.timestamp;
    }

    function underwrite(bytes32 processId) 
        external override 
        onlyPolicyFlow("Pool")
        returns(bool success)
    {
        // check that application is in applied state
        IPolicy.Application memory application = _policy.getApplication(processId);
        require(
            application.state == IPolicy.ApplicationState.Applied,
            "ERROR:POL-020:APPLICATION_STATE_INVALID"
        );

        // determine riskpool responsible for application
        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        uint256 riskpoolId = _riskpoolIdForProductId[metadata.productId];
        require(
            _component.getComponentState(riskpoolId) == IComponent.ComponentState.Active, 
            "ERROR:POL-021:RISKPOOL_NOT_ACTIVE"
        );

        // calculate required collateral amount
        uint256 sumInsuredAmount = application.sumInsuredAmount;
        uint256 collateralAmount = calculateCollateral(riskpoolId, sumInsuredAmount);
        _collateralAmount[processId] = collateralAmount;

        emit LogRiskpoolRequiredCollateral(processId, sumInsuredAmount, collateralAmount);

        // check that riskpool stays inside sum insured cap when underwriting this application 
        IPool.Pool storage pool = _riskpools[riskpoolId];
        require(
            pool.sumOfSumInsuredCap >= pool.sumOfSumInsuredAtRisk + sumInsuredAmount,
            "ERROR:POL-022:RISKPOOL_SUM_INSURED_CAP_EXCEEDED"
        );

        // ask riskpool to secure application
        IRiskpool riskpool = _getRiskpoolComponent(metadata);
        success = riskpool.collateralizePolicy(processId, collateralAmount);

        if (success) {
            pool.sumOfSumInsuredAtRisk += sumInsuredAmount;
            pool.lockedCapital += collateralAmount;
            pool.updatedAt = block.timestamp;

            emit LogRiskpoolCollateralizationSucceeded(riskpoolId, processId, sumInsuredAmount);
        } else {
            emit LogRiskpoolCollateralizationFailed(riskpoolId, processId, sumInsuredAmount);
        }
    }


    function calculateCollateral(uint256 riskpoolId, uint256 sumInsuredAmount) 
        public
        view 
        returns (uint256 collateralAmount) 
    {
        uint256 collateralization = getRiskpool(riskpoolId).collateralizationLevel;

        // fully collateralized case
        if (collateralization == FULL_COLLATERALIZATION_LEVEL) {
            collateralAmount = sumInsuredAmount;
        // over or under collateralized case
        } else if (collateralization > 0) {
            collateralAmount = (collateralization * sumInsuredAmount) / FULL_COLLATERALIZATION_LEVEL;
        }
        // collateralization == 0, eg complete risk coverd by re insurance outside gif
        else {
            collateralAmount = 0;
        }
    }


    function processPremium(bytes32 processId, uint256 amount) 
        external override
        onlyPolicyFlow("Pool")
    {
        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        IRiskpool riskpool = _getRiskpoolComponent(metadata);
        riskpool.processPolicyPremium(processId, amount);

        uint256 riskpoolId = _riskpoolIdForProductId[metadata.productId];
        IPool.Pool storage pool = _riskpools[riskpoolId];
        pool.balance += amount;
        pool.updatedAt = block.timestamp;
    }


    function processPayout(bytes32 processId, uint256 amount) 
        external override
        onlyPolicyFlow("Pool")
    {
        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        uint256 riskpoolId = _riskpoolIdForProductId[metadata.productId];
        IPool.Pool storage pool = _riskpools[riskpoolId];
        require(pool.createdAt > 0, "ERROR:POL-026:RISKPOOL_ID_INVALID");
        require(pool.capital >= amount, "ERROR:POL-027:CAPITAL_TOO_LOW");
        require(pool.lockedCapital >= amount, "ERROR:POL-028:LOCKED_CAPITAL_TOO_LOW");
        require(pool.balance >= amount, "ERROR:POL-029:BALANCE_TOO_LOW");

        pool.capital -= amount;
        pool.lockedCapital -= amount;
        pool.balance -= amount;
        pool.updatedAt = block.timestamp; // solhint-disable-line

        IRiskpool riskpool = _getRiskpoolComponent(metadata);
        riskpool.processPolicyPayout(processId, amount);
    }


    function release(bytes32 processId) 
        external override
        onlyPolicyFlow("Pool")
    {
        IPolicy.Policy memory policy = _policy.getPolicy(processId);
        require(
            policy.state == IPolicy.PolicyState.Closed,
            "ERROR:POL-025:POLICY_STATE_INVALID"
        );

        IPolicy.Metadata memory metadata = _policy.getMetadata(processId);
        IRiskpool riskpool = _getRiskpoolComponent(metadata);
        riskpool.releasePolicy(processId);

        IPolicy.Application memory application = _policy.getApplication(processId);

        uint256 riskpoolId = _riskpoolIdForProductId[metadata.productId];
        IPool.Pool storage pool = _riskpools[riskpoolId];
        uint256 remainingCollateralAmount = _collateralAmount[processId] - policy.payoutAmount;

        pool.sumOfSumInsuredAtRisk -= application.sumInsuredAmount;
        pool.lockedCapital -= remainingCollateralAmount;
        pool.updatedAt = block.timestamp; // solhint-disable-line

        // free memory
        delete _collateralAmount[processId];
        emit LogRiskpoolCollateralReleased(riskpoolId, processId, remainingCollateralAmount);
    }

    function setMaximumNumberOfActiveBundles(uint256 riskpoolId, uint256 maxNumberOfActiveBundles)
        external 
        onlyRiskpoolService
    {
        require(maxNumberOfActiveBundles > 0, "ERROR:POL-032:MAX_NUMBER_OF_ACTIVE_BUNDLES_INVALID");
        _maxmimumNumberOfActiveBundlesForRiskpoolId[riskpoolId] = maxNumberOfActiveBundles;
    }

    function getMaximumNumberOfActiveBundles(uint256 riskpoolId) public view returns(uint256 maximumNumberOfActiveBundles) {
        return _maxmimumNumberOfActiveBundlesForRiskpoolId[riskpoolId];
    }
    
    function riskpools() external view returns(uint256 idx) { return _riskpoolIds.length; }


    function getRiskpool(uint256 riskpoolId) public view returns(IPool.Pool memory riskPool) {
        riskPool = _riskpools[riskpoolId];
        require(riskPool.createdAt > 0, "ERROR:POL-040:RISKPOOL_NOT_REGISTERED");
    }

    function getRiskPoolForProduct(uint256 productId) external view returns (uint256 riskpoolId) {
        return _riskpoolIdForProductId[productId];
    }

    function activeBundles(uint256 riskpoolId) external view returns(uint256 numberOfActiveBundles) {
        return EnumerableSet.length(_activeBundleIdsForRiskpoolId[riskpoolId]);
    }

    function getActiveBundleId(uint256 riskpoolId, uint256 bundleIdx) external view returns(uint256 bundleId) {
        require(
            bundleIdx < EnumerableSet.length(_activeBundleIdsForRiskpoolId[riskpoolId]),
            "ERROR:POL-041:BUNDLE_IDX_TOO_LARGE"
        );

        return EnumerableSet.at(_activeBundleIdsForRiskpoolId[riskpoolId], bundleIdx);
    }

    function addBundleIdToActiveSet(uint256 riskpoolId, uint256 bundleId) 
        external
        onlyRiskpoolService
    {
        require(
            !EnumerableSet.contains(_activeBundleIdsForRiskpoolId[riskpoolId], bundleId), 
            "ERROR:POL-042:BUNDLE_ID_ALREADY_IN_SET"
        );
        require(
            EnumerableSet.length(_activeBundleIdsForRiskpoolId[riskpoolId]) < _maxmimumNumberOfActiveBundlesForRiskpoolId[riskpoolId], 
            "ERROR:POL-043:MAXIMUM_NUMBER_OF_ACTIVE_BUNDLES_REACHED"
        );

        EnumerableSet.add(_activeBundleIdsForRiskpoolId[riskpoolId], bundleId);
    }

    function removeBundleIdFromActiveSet(uint256 riskpoolId, uint256 bundleId) 
        external
        onlyRiskpoolService
    {
        require(
            EnumerableSet.contains(_activeBundleIdsForRiskpoolId[riskpoolId], bundleId), 
            "ERROR:POL-044:BUNDLE_ID_NOT_IN_SET"
        );

        EnumerableSet.remove(_activeBundleIdsForRiskpoolId[riskpoolId], bundleId);
    }

    function getFullCollateralizationLevel() external pure returns (uint256) {
        return FULL_COLLATERALIZATION_LEVEL;
    }

    function _getRiskpoolComponent(IPolicy.Metadata memory metadata) internal view returns (IRiskpool riskpool) {
        uint256 riskpoolId = _riskpoolIdForProductId[metadata.productId];
        require(riskpoolId > 0, "ERROR:POL-045:RISKPOOL_DOES_NOT_EXIST");

        riskpool = _getRiskpoolForId(riskpoolId);
    }

    function _getRiskpoolForId(uint256 riskpoolId) internal view returns (IRiskpool riskpool) {
        require(_component.isRiskpool(riskpoolId), "ERROR:POL-046:COMPONENT_NOT_RISKPOOL");
        
        IComponent cmp = _component.getComponent(riskpoolId);
        riskpool = IRiskpool(address(cmp));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPool {

    event LogRiskpoolRegistered(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token, 
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    );
    
    event LogRiskpoolRequiredCollateral(bytes32 processId, uint256 sumInsured, uint256 collateral);
    event LogRiskpoolCollateralizationFailed(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralizationSucceeded(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralReleased(uint256 riskpoolId, bytes32 processId, uint256 amount);

    struct Pool {
        uint256 id; // matches component id of riskpool
        address wallet; // riskpool wallet
        address erc20Token; // the value token of the riskpool
        uint256 collateralizationLevel; // required collateralization level to cover new policies 
        uint256 sumOfSumInsuredCap; // max sum of sum insured the pool is allowed to secure
        uint256 sumOfSumInsuredAtRisk; // current sum of sum insured at risk in this pool
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function registerRiskpool(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token,
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    ) external;

    function setRiskpoolForProduct(uint256 productId, uint256 riskpoolId) external;

    function underwrite(bytes32 processId) external returns(bool success);
    function processPremium(bytes32 processId, uint256 amount) external;
    function processPayout(bytes32 processId, uint256 amount) external;
    function release(bytes32 processId) external; 
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IERC20.sol";

// inspired/informed by
// https://soliditydeveloper.com/safe-erc20
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC20/ERC20.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC20/utils/SafeERC20.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/utils/Address.sol
// https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
library TransferHelper {

    event LogTransferHelperInputValidation1Failed(bool tokenIsContract, address from, address to);
    event LogTransferHelperInputValidation2Failed(uint256 balance, uint256 allowance);
    event LogTransferHelperCallFailed(bool callSuccess, uint256 returnDataLength, bytes returnData);

    function unifiedTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    )
        internal
        returns(bool success)
    {
        // input validation step 1
        address tokenAddress = address(token);
        bool tokenIsContract = (tokenAddress.code.length > 0);
        if (from == address(0) || to == address (0) || !tokenIsContract) {
            emit LogTransferHelperInputValidation1Failed(tokenIsContract, from, to);
            return false;
        }
        
        // input validation step 2
        uint256 balance = token.balanceOf(from);
        uint256 allowance = token.allowance(from, address(this));
        if (balance < value || allowance < value) {
            emit LogTransferHelperInputValidation2Failed(balance, allowance);
            return false;
        }

        // low-level call to transferFrom
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool callSuccess, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd, 
                from, 
                to, 
                value));

        success = callSuccess && (false
            || data.length == 0 
            || (data.length == 32 && abi.decode(data, (bool))));

        if (!success) {
            emit LogTransferHelperCallFailed(callSuccess, data.length, data);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;
import "IERC20.sol";

interface ITreasury {

    event LogTreasurySuspended();
    event LogTreasuryResumed();

    event LogTreasuryProductTokenSet(uint256 productId, uint256 riskpoolId, address erc20Address);
    event LogTreasuryInstanceWalletSet(address walletAddress);
    event LogTreasuryRiskpoolWalletSet(uint256 riskpoolId, address walletAddress);

    event LogTreasuryPremiumFeesSet(uint256 productId, uint256 fixedFee, uint256 fractionalFee);
    event LogTreasuryCapitalFeesSet(uint256 riskpoolId, uint256 fixedFee, uint256 fractionalFee);

    event LogTreasuryPremiumTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryPayoutTransferred(address riskpoolWalletAddress, address to, uint256 amount);
    event LogTreasuryCapitalTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryFeesTransferred(address from, address instanceWalletAddress, uint256 amount);
    event LogTreasuryWithdrawalTransferred(address riskpoolWalletAddress, address to, uint256 amount);

    event LogTreasuryPremiumProcessed(bytes32 processId, uint256 amount);
    event LogTreasuryPayoutProcessed(uint256 riskpoolId, address to, uint256 amount);
    event LogTreasuryCapitalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);
    event LogTreasuryWithdrawalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);

    struct FeeSpecification {
        uint256 componentId;
        uint256 fixedFee;
        uint256 fractionalFee;
        bytes feeCalculationData;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function setProductToken(uint256 productId, address erc20Address) external;

    function setInstanceWallet(address instanceWalletAddress) external;
    function setRiskpoolWallet(uint256 riskpoolId, address riskpoolWalletAddress) external;

    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    )
        external view returns(FeeSpecification memory feeSpec);
    
    function setPremiumFees(FeeSpecification calldata feeSpec) external;
    function setCapitalFees(FeeSpecification calldata feeSpec) external;
    
    function processPremium(bytes32 processId) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPremium(bytes32 processId, uint256 amount) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPayout(bytes32 processId, uint256 payoutId) external 
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        );
    
    function processCapital(uint256 bundleId, uint256 capitalAmount) external 
        returns(
            uint256 feeAmount,
            uint256 netCapitalAmount
        );

    function processWithdrawal(uint256 bundleId, uint256 amount) external
        returns(
            uint256 feeAmount,
            uint256 netAmount
        );

    function getComponentToken(uint256 componentId) external view returns(IERC20 token);
    function getFeeSpecification(uint256 componentId) external view returns(FeeSpecification memory feeSpecification);

    function getFractionFullUnit() external view returns(uint256);
    function getInstanceWallet() external view returns(address instanceWalletAddress);
    function getRiskpoolWallet(uint256 riskpoolId) external view returns(address riskpoolWalletAddress);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}