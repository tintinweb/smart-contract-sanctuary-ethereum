/**
* ENGA Federation Controller.
* @author Mehdikovic
* Date created: 2022.04.05
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import { IController } from "../interfaces/fundraising/IController.sol";
import { EngalandBase } from "../common/EngalandBase.sol";

import { IEngaToken } from "../interfaces/fundraising/IEngaToken.sol";
import { ITokenManager } from "../interfaces/fundraising/ITokenManager.sol";
import { IMarketMaker } from "../interfaces/fundraising/IMarketMaker.sol";
import { IBancor } from "../interfaces/fundraising/IBancor.sol";
import { ITap } from "../interfaces/fundraising/ITap.sol";
import { IVaultERC20 } from "../interfaces/finance/IVaultERC20.sol";
import { IKycAuthorization } from "../interfaces/access/IKycAuthorization.sol";
import { IPreSale, SaleState } from "../interfaces/fundraising/IPreSale.sol";

import { EngalandAccessControl } from "../access/EngalandAccessControl.sol";
import { Utils } from "../lib/Utils.sol";


contract Controller is IController, EngalandAccessControl {
    /**
    bytes32 public constant MINTER_ROLE                                = keccak256("MINTER_ROLE");;
    bytes32 public constant BURNER_ROLE                                = keccak256("BURNER_ROLE");;
    bytes32 public constant SUSPEND_ROLE                               = keccak256("SUSPEND_ROLE");
    bytes32 public constant UPDATE_FEES_ROLE                           = keccak256("UPDATE_FEES_ROLE");
    bytes32 public constant UPDATE_COLLATERAL_TOKEN_ROLE               = keccak256("UPDATE_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE  = keccak256("UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE");
    bytes32 public constant UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE = keccak256("UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE");
    bytes32 public constant UPDATE_TAPPED_TOKEN_ROLE                   = keccak256("UPDATE_TAPPED_TOKEN_ROLE");
    bytes32 public constant TREASURY_TRANSFER_ROLE                     = keccak256("TREASURY_TRANSFER_ROLE");
    bytes32 public constant TRANSFER_ROLE                              = keccak256("TRANSFER_ROLE");
    bytes32 public constant VESTING_ROLE                               = keccak256("VESTING_ROLE");
    bytes32 public constant REVOKE_ROLE                                = keccak256("REVOKE_ROLE");
    bytes32 public constant RELEASE_ROLE                               = keccak256("RELEASE_ROLE");
    */
    bytes32 public constant MINTER_ROLE                                = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant BURNER_ROLE                                = 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848;
    bytes32 public constant SUSPEND_ROLE                               = 0x091ece3b4e3685ed6d27f340286ac896d55b838dc58d4045d967a5d58f93d268;
    bytes32 public constant UPDATE_FEES_ROLE                           = 0x5f9be2932ed3a723f295a763be1804c7ebfd1a41c1348fb8bdf5be1c5cdca822;
    bytes32 public constant UPDATE_COLLATERAL_TOKEN_ROLE               = 0xe0565c2c43e0d841e206bb36a37f12f22584b4652ccee6f9e0c071b697a2e13d;
    bytes32 public constant UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE  = 0x5d94de7e429250eee4ff97e30ab9f383bea3cd564d6780e0a9e965b1add1d207;
    bytes32 public constant UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE = 0x57c9c67896cf0a4ffe92cbea66c2f7c34380af06bf14215dabb078cf8a6d99e1;
    bytes32 public constant UPDATE_TAPPED_TOKEN_ROLE                   = 0x83201394534c53ae0b4696fd49a933082d3e0525aa5a3d0a14a2f51e12213288;
    bytes32 public constant TREASURY_TRANSFER_ROLE                     = 0x694c459f7a04364da937ae77333217d0211063f4ed5560eeb8f79451399c153b;
    bytes32 public constant TRANSFER_ROLE                              = 0x8502233096d909befbda0999bb8ea2f3a6be3c138b9fbf003752a4c8bce86f6c;
    bytes32 public constant VESTING_ROLE                               = 0x6343452265350cc926492d9bfc7710ca06328d7c328cdb091fde925c1441e7a8;
    bytes32 public constant REVOKE_ROLE                                = 0x5297e68f3a27f04914f2c6db0ad63b5e5c8173cebcc1a5341df045cf6dad7adc;
    bytes32 public constant RELEASE_ROLE                               = 0x63f32341a2c9659e28e2f3da14b2d4dc3b076a5eebd426f016534536cda2948e;

    string private constant ERROR_INVALID_CONTRACT            = "ERROR_INVALID_CONTRACT";
    string private constant ERROR_INVALID_USER_ADDRESS        = "ERROR_INVALID_USER_ADDRESS";
    string private constant ERROR_EXTRA_SALE_UNNECESSARY      = "ERROR_SEEDSALE_AND_PRIVATESALE_WENT_WELL_NO_NEED_FOR_AN_EXTRA_SALE";
    string private constant ERROR_TAP_CANNOT_BE_REMOVED       = "ERROR_COLLATREAL_STILL_EXISTS_IN_MARKETMAKER_FIRST_REMOVE_MARKETMAKER_THEN_TAP";
    string private constant ERROR_COLLATERAL_CANNOT_BE_ADDED  = "ERROR_TAP_TOKEN_IS_NOT_TAPPED_TO_LET_MARKETMAKER_DO_ITS_JOB";
    string private constant ERROR_RELEASE_ACCESS_DENIED       = "ERROR_RELEASE_ACCESS_DENIED";
    string private constant ERROR_NOT_KYC                     = "ERROR_NOT_KYC";
    string private constant ERROR_CONTROLLER_MISMATCH         = "ERROR_CONTROLLER_MISMATCH";
    string private constant ERROR_SALE_MUST_BE_PENDING        = "ERROR_SALE_MUST_BE_PENDING";
    string private constant ERROR_VESTING_IS_CLOSED           = "ERROR_VESTING_IS_CLOSED";
    string private constant ERROR_SALE_DUPLICATION            = "ERROR_SALE_DUPLICATION";
    string private constant ERROR_COLLATERAL_NEEDED           = "ERROR_COLLATERAL_NEEDED";
    string private constant ERROR_WRONG_STATE                 = "ERROR_WRONG_STATE";
    string private constant ERROR_CONTRACT_DOES_NOT_EXIST     = "ERROR_CONTRACT_DOES_NOT_EXIST";
    string private constant ERROR_CONTRACT_ALREADY_EXISTS     = "ERROR_CONTRACT_ALREADY_EXISTS";
    string private constant ERROR_PROTOCOL_IS_LOCKED          = "ERROR_PROTOCOL_IS_LOCKED";

    event PreSaleChanged(address previousSale, address newSale);
    
    ControllerState   public state = ControllerState.Constructed;
    bool              public isProtocolLocked;
    
    address  public engaToken;
    address  public tokenManager;
    address  public marketMaker;
    address  public bancorFormula;
    address  public tap;
    address  public reserve;
    address  public treasury;
    address  public kyc;
    IPreSale public preSale;

    /**
    * @notice Constrcut Controller
    * @param _owner  the address of the multisig contract
    */
    constructor(address _owner) EngalandAccessControl(_owner) {
        _grantRole(keccak256("TEMP"), _msgSender());
    }

    function initContracts(
        address _engaToken,
        address _tokenManager,
        address _marketMaker,
        address _bancorFormula,
        address _tap,
        address _reserve,
        address _treasury,
        address _kyc
    )
        external
        onlyRole(keccak256("TEMP"))
    {
        require(state == ControllerState.Constructed);

        Utils.enforceHasContractCode(_engaToken, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_tokenManager, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_marketMaker, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_bancorFormula, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_tap, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_reserve, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_treasury, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_kyc, ERROR_INVALID_CONTRACT);

        engaToken = _engaToken;
        tokenManager = _tokenManager;
        marketMaker = _marketMaker;
        bancorFormula = _bancorFormula;
        tap = _tap;
        reserve = _reserve;
        treasury = _treasury;
        kyc = _kyc;

        EngalandBase(engaToken).grantRole(MINTER_ROLE, tokenManager);
        EngalandBase(engaToken).grantRole(BURNER_ROLE, tokenManager);

        EngalandBase(tokenManager).grantRole(MINTER_ROLE, marketMaker);
        EngalandBase(tokenManager).grantRole(BURNER_ROLE, marketMaker);

        EngalandBase(reserve).grantRole(TRANSFER_ROLE, marketMaker);
        EngalandBase(reserve).grantRole(TRANSFER_ROLE, tap);
        
        state = ControllerState.ContractsDeployed;
    }

    /* STATE MODIFIERS */

    /** INITIALIZERS **/

    /**
    * @notice Initialzie The Protocol
    * @param _stakeHolders                the address of the deployed stakeHolders
    * @param _seedSale                    the address of the deployed seedSale
    * @param _preSale                     the address of the deployed preSale
    * @param _batchBlocks                 the number of blocks batches are to last
    * @param _buyFeePct                   the fee to be deducted from buy orders [in PCT_BASE]
    * @param _sellFeePct                  the fee to be deducted from sell orders [in PCT_BASE
    * @param _maximumTapRateIncreasePct   the maximum tap rate increase percentage allowed [in PCT_BASE]
    * @param _maximumTapFloorDecreasePct  the maximum tap floor decrease percentage allowed [in PCT_BASE
    */
    function initializeProtocol(
        address _stakeHolders,
        address _seedSale,
        address _preSale,
        uint256 _batchBlocks,
        uint256 _buyFeePct,
        uint256 _sellFeePct,
        uint256 _maximumTapRateIncreasePct,
        uint256 _maximumTapFloorDecreasePct
    )
        external 
        onlyRole(keccak256("TEMP"))
    {
        require(state == ControllerState.ContractsDeployed);
        require(address(preSale) == address(0));
        
        Utils.enforceHasContractCode(_preSale, ERROR_INVALID_CONTRACT);
        require(IPreSale(_preSale).getController() == address(this), ERROR_CONTROLLER_MISMATCH);
        require(IPreSale(_preSale).state() == SaleState.Pending, ERROR_SALE_MUST_BE_PENDING);

        ITokenManager(tokenManager).initialize(_stakeHolders, _seedSale);
        IMarketMaker(marketMaker).initialize(_batchBlocks, _buyFeePct, _sellFeePct);
        ITap(tap).initialize(_batchBlocks, _maximumTapRateIncreasePct, _maximumTapFloorDecreasePct);

        _grantRole(VESTING_ROLE, _preSale);
        _grantRole(REVOKE_ROLE, _preSale);
        preSale = IPreSale(_preSale);

        _revokeRole(keccak256("TEMP"), _msgSender());
        state = ControllerState.Initialized;
    }

    /**
    * @notice Lock the hole protocol in emergency
    * @param _value a boolean indicating if the protocol is locked
    */
    function setProtocolState(bool _value) external onlyMultisig {
        require(state == ControllerState.Initialized);
        require(isProtocolLocked != _value);
        
        isProtocolLocked = _value;
    }

    /**
    * @notice Grant extra roles to an account if needed
    * @param _contract the address of the contract which is granting the role
    * @param _role     the role to be granted
    * @param _to       to whom(user or contract) the role is being granted
    */
    function grantRoleTo(address _contract, bytes32 _role, address _to) external onlyMultisig onlyOpenProtocol {
        require(EngalandBase(_contract).isInitialized());
        EngalandBase(_contract).grantRole(_role, _to);
    }

    /**
    * @notice Revoke extra roles from an account if needed
    * @param _contract the address of the contract which is revoking the role
    * @param _role     the role to be revoked
    * @param _from     from whom(user or contract) the role is being revoked
    */
    function revokeRoleFrom(address _contract, bytes32 _role, address _from) external onlyMultisig onlyOpenProtocol {
        require(EngalandBase(_contract).isInitialized());
        EngalandBase(_contract).revokeRole(_role, _from);
    }
    
    /**
    * @notice Activate another PreSale in case the previous one is failed, if the previous one is not failed, the new one will be ignored
    * @param _newSale the address of the new deployed sale
    */
    //NOTE we completely trust our PreSale, you should be careful if you're going to use another written PreSale other than ours, interface is crucial but implementation is much more important
    function setNewSaleAddress(address _newSale) external onlyMultisig onlyOpenProtocol { 
        Utils.enforceHasContractCode(_newSale, ERROR_INVALID_CONTRACT);
        require(IPreSale(_newSale).getController() == address(this), ERROR_CONTROLLER_MISMATCH);
        require(IPreSale(_newSale).state() == SaleState.Pending, ERROR_SALE_MUST_BE_PENDING);
        require(_newSale != address(preSale), ERROR_SALE_DUPLICATION);
        require(!ITokenManager(tokenManager).isVestingClosed(), ERROR_VESTING_IS_CLOSED);
        require(preSale.state() == SaleState.Refunding || preSale.state() == SaleState.Closed, ERROR_EXTRA_SALE_UNNECESSARY);

        address previousSale = address(preSale);

        if (hasRole(VESTING_ROLE, previousSale)) {
            _revokeRole(VESTING_ROLE, previousSale);
        }

        _grantRole(VESTING_ROLE, _newSale);
        _grantRole(REVOKE_ROLE, _newSale);
        preSale = IPreSale(_newSale);

        emit PreSaleChanged(previousSale, _newSale);
    }


    /************************************/
    /**** PRESALE SPECIFIC INTERFACE ****/
    /************************************/

    function closeSale() external onlyOpenProtocol {
        preSale.close();
    }

    function openSaleByDate(uint256 _openDate) external onlyMultisig onlyOpenProtocol {
        preSale.openByDate(_openDate);
    }

    function openSaleNow() external onlyMultisig onlyOpenProtocol {
        preSale.openNow();
    }

    function contribute(uint256 _value) external onlyOpenProtocol {
        require(IKycAuthorization(kyc).getKycOfUser(_msgSender()), ERROR_NOT_KYC);
        
        preSale.contribute(_msgSender(), _value);
    }

    function refund(address _contributor, bytes32 _vestedPurchaseId) external {
        preSale.refund(_contributor, _vestedPurchaseId);
    }
    
    /************************************/
    /**** PRESALE SPECIFIC INTERFACE ****/
    /************************************/




    /************************************/
    /****** KYC SPECIFIC INTERFACE ******/
    /************************************/
    
    function enableKyc() external onlyMultisig onlyOpenProtocol {
        IKycAuthorization(kyc).enableKyc();
    }
    
    function disableKyc() external onlyMultisig onlyOpenProtocol {
        IKycAuthorization(kyc).disableKyc();
    }

    function addKycUser(address _user) external onlyMultisig onlyOpenProtocol {
        IKycAuthorization(kyc).addKycUser(_user);
    }

    function removeKycUser(address _user) external onlyMultisig onlyOpenProtocol {
        IKycAuthorization(kyc).removeKycUser(_user);
    }

    function addKycUserBatch(address[] memory _users) external onlyMultisig onlyOpenProtocol {
        IKycAuthorization(kyc).addKycUserBatch(_users);
    }
    
    function removeKycUserBatch(address[] memory _users) external onlyMultisig onlyOpenProtocol {
        IKycAuthorization(kyc).removeKycUserBatch(_users);
    }
    
    function getKycOfUser(address _user) external view returns (bool) {
        return IKycAuthorization(kyc).getKycOfUser(_user);
    }

    /************************************/
    /****** KYC SPECIFIC INTERFACE ******/
    /************************************/



    /************************************/
    /*** Treasury SPECIFIC INTERFACE ****/
    /************************************/

    function treasuryTransfer(address _token, address _to, uint256 _value) external onlyMultisigOrRole(TREASURY_TRANSFER_ROLE) onlyOpenProtocol {
        IVaultERC20(treasury).transferERC20(_token, _to, _value);
    }

    /************************************/
    /*** Treasury SPECIFIC INTERFACE ****/
    /************************************/




    /************************************/
    /* TokenManager SPECIFIC INTERFACE **/
    /************************************/
    
    function createVesting(address _beneficiary, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _end, bool _revocable)
        external
        onlyRole(VESTING_ROLE)
        onlyOpenProtocol
        returns (bytes32)
    {
        address vestingCreator = _msgSender();
        return ITokenManager(tokenManager).createVesting(_beneficiary, vestingCreator, _amount, _start, _cliff, _end, _revocable);
    }
    
    function revoke(bytes32 vestingId) external onlyRole(REVOKE_ROLE) onlyOpenProtocol {
        ITokenManager(tokenManager).revoke(vestingId);
    }

    function release(bytes32 vestingId) external onlyOpenProtocol {
        bool isMultisig = _msgSender() == owner;
        bool isBeneficiary = _msgSender() == ITokenManager(tokenManager).getVestingOwner(vestingId);
        bool hasReleaseRole = hasRole(RELEASE_ROLE, _msgSender());
        
        require(isBeneficiary || hasReleaseRole || isMultisig, ERROR_RELEASE_ACCESS_DENIED);
        ITokenManager(tokenManager).release(vestingId);
    }
    
    function closeVestingProcess() external onlyMultisig onlyOpenProtocol {
        ITokenManager(tokenManager).closeVestingProcess();
    }

    function withdrawTokenManger(address _token, address _receiver, uint256 _amount) external onlyMultisig onlyOpenProtocol {
        ITokenManager(tokenManager).withdraw(_token, _receiver, _amount);
    }

    /************************************/
    /* TokenManager SPECIFIC INTERFACE **/
    /************************************/




    /************************************/
    /** MarketMaker SPECIFIC INTERFACE **/
    /************************************/
    
    function collateralsToBeClaimed(address _collateral) external view returns(uint256) {
        return IMarketMaker(marketMaker).collateralsToBeClaimed(_collateral);
    }

    function openPublicTrading(address[] memory _collaterals) external onlyMultisig onlyOpenProtocol {
        if (preSale.state() != SaleState.Closed) {
            preSale.close(); // reverts if conditions aren't met
        }
        
        if (!ITokenManager(tokenManager).isVestingClosed()) {
            ITokenManager(tokenManager).closeVestingProcess();
        }

        for (uint256 i = 0; i < _collaterals.length; i++) {
            require(IMarketMaker(marketMaker).collateralIsWhitelisted(_collaterals[i]));
            ITap(tap).resetTappedToken(_collaterals[i]);
        }

        IMarketMaker(marketMaker).open();
    }

    function suspendMarketMaker(bool _value) external onlyMultisigOrRole(SUSPEND_ROLE) onlyOpenProtocol {
        IMarketMaker(marketMaker).suspend(_value);
    }

    function updateBancorFormula(address _bancor) external onlyMultisig onlyOpenProtocol {
        IMarketMaker(marketMaker).updateBancorFormula(_bancor);
        bancorFormula = _bancor;
    }

    function updateTreasury(address payable _treasury) external onlyMultisig onlyOpenProtocol {
        IMarketMaker(marketMaker).updateTreasury(_treasury);
        treasury = _treasury;
    }

    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) external onlyMultisigOrRole(UPDATE_FEES_ROLE) onlyOpenProtocol {
        IMarketMaker(marketMaker).updateFees(_buyFeePct, _sellFeePct);
    }

    function addCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage,
        uint256 _rate,
        uint256 _floor
    )
        external
        onlyMultisig
        onlyOpenProtocol
    {
        IMarketMaker(marketMaker).addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
        
        if (_rate > 0) {
            ITap(tap).addTappedToken(_collateral, _rate, _floor);
        }
    }

    function reAddCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage
    )
    	external
        onlyMultisig
        onlyOpenProtocol
    {
        require(ITap(tap).tokenIsTapped(_collateral), ERROR_COLLATERAL_CANNOT_BE_ADDED);
        IMarketMaker(marketMaker).addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    function removeCollateralToken(address _collateral) external onlyMultisig onlyOpenProtocol {
        IMarketMaker(marketMaker).removeCollateralToken(_collateral);
    }
    
    function updateCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32 _reserveRatio,
        uint256 _slippage
    )
        external
        onlyMultisigOrRole(UPDATE_COLLATERAL_TOKEN_ROLE)
        onlyOpenProtocol
    {
        IMarketMaker(marketMaker).updateCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }
    
    function openBuyOrder(address _collateral, uint256 _value) external onlyOpenProtocol {
        require(IKycAuthorization(kyc).getKycOfUser(_msgSender()), ERROR_NOT_KYC);
        IMarketMaker(marketMaker).openBuyOrder(_msgSender(), _collateral, _value);
    }

    function openSellOrder(address _collateral, uint256 _amount) external onlyOpenProtocol {
        require(IKycAuthorization(kyc).getKycOfUser(_msgSender()), ERROR_NOT_KYC);
        IMarketMaker(marketMaker).openSellOrder(_msgSender(), _collateral, _amount);
    }
    
    function claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) external onlyOpenProtocol {
        IMarketMaker(marketMaker).claimBuyOrder(_buyer, _batchId, _collateral);
    }
    
    function claimSellOrder(address _seller, uint256 _batchId, address _collateral) external onlyOpenProtocol {
        IMarketMaker(marketMaker).claimSellOrder(_seller, _batchId, _collateral);
    }

    function claimCancelledBuyOrder(address _buyer, uint256 _batchId, address _collateral) external onlyOpenProtocol {
        IMarketMaker(marketMaker).claimCancelledBuyOrder(_buyer, _batchId, _collateral);
    }

    function claimCancelledSellOrder(address _seller, uint256 _batchId, address _collateral) external onlyOpenProtocol {
        IMarketMaker(marketMaker).claimCancelledSellOrder(_seller, _batchId, _collateral);
    }
    /************************************/
    /** MarketMaker SPECIFIC INTERFACE **/
    /************************************/




    /************************************/
    /****** TAP SPECIFIC INTERFACE ******/
    /************************************/
    
    function updateBeneficiary(address payable _beneficiary) external onlyMultisig onlyOpenProtocol {
        ITap(tap).updateBeneficiary(_beneficiary);
    }
    
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external onlyMultisigOrRole(UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE) onlyOpenProtocol {
        ITap(tap).updateMaximumTapRateIncreasePct(_maximumTapRateIncreasePct);
    }
    
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external onlyMultisigOrRole(UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE) onlyOpenProtocol {
        ITap(tap).updateMaximumTapFloorDecreasePct(_maximumTapFloorDecreasePct);
    }
    
    function removeTappedToken(address _token) external onlyMultisig onlyOpenProtocol {
        require(!IMarketMaker(marketMaker).collateralIsWhitelisted(_token), ERROR_TAP_CANNOT_BE_REMOVED);
        ITap(tap).removeTappedToken(_token);
    }
    
    function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external onlyMultisigOrRole(UPDATE_TAPPED_TOKEN_ROLE) onlyOpenProtocol {
        ITap(tap).updateTappedToken(_token, _rate, _floor);
    }
    
    function updateTappedAmount(address _token) external onlyOpenProtocol {
        ITap(tap).updateTappedAmount(_token);
    }
    
    function withdrawTap(address _collateral) external onlyMultisig onlyOpenProtocol {
        ITap(tap).withdraw(_collateral);
    }
    
    function getMaximumWithdrawal(address _token) external view returns (uint256) {
        return ITap(tap).getMaximumWithdrawal(_token);
    }
    /************************************/
    /****** TAP SPECIFIC INTERFACE ******/
    /************************************/

    /* VIEW */
    function beneficiary() external view returns(address) {
        return owner;
    }

    /* MODIFIERS */
    modifier onlyOpenProtocol {
        require(state == ControllerState.Initialized);
        require(!isProtocolLocked, ERROR_PROTOCOL_IS_LOCKED);
        _;
    }
}

/**
* ENGA Federation Controller Interface.
* @author Mehdikovic
* Date created: 2022.04.05
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface IController {
    enum ControllerState {
        Constructed,
        ContractsDeployed,
        Initialized
    }
    
    function setNewSaleAddress(address _newSale) external;
    
    function state() external view returns (ControllerState);
    function engaToken() external view returns(address);
    function tokenManager() external view returns(address);
    function marketMaker() external view returns(address);
    function bancorFormula() external view returns(address);
    function beneficiary() external view returns(address);
    function tap() external view returns(address);
    function reserve() external view returns(address);
    function treasury() external view returns(address);
    function kyc() external view returns(address);
    //function preSale() external view returns(address);

    /************************************/
    /**** PRESALE SPECIFIC INTERFACE ****/
    /************************************/
    function closeSale() external;
    function openSaleByDate(uint256 _openDate) external;
    function openSaleNow() external;
    function contribute(uint256 _value) external;
    function refund(address _contributor, bytes32 _vestedPurchaseId) external;
    
    /************************************/
    /****** KYC SPECIFIC INTERFACE ******/
    /************************************/
    function enableKyc() external;
    function disableKyc() external;
    function addKycUser(address _user) external;
    function removeKycUser(address _user) external;
    function getKycOfUser(address _user) external view returns (bool);

    /************************************/
    /*** Treasury SPECIFIC INTERFACE ****/
    /************************************/
    function treasuryTransfer(address _token, address _to, uint256 _value) external;

    /************************************/
    /* TokenManager SPECIFIC INTERFACE **/
    /************************************/
    function createVesting(address _beneficiary, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _end, bool _revocable) external returns (bytes32);
    function revoke(bytes32 vestingId) external;
    function release(bytes32 vestingId) external;
    function closeVestingProcess() external;
    function withdrawTokenManger(address _token, address _receiver, uint256 _amount) external;

    /************************************/
    /** MarketMaker SPECIFIC INTERFACE **/
    /************************************/
    function collateralsToBeClaimed(address _collateral) external view returns(uint256);
    function openPublicTrading(address[] memory collaterals) external;
    function suspendMarketMaker(bool _value) external;
    function updateBancorFormula(address _bancor) external;
    function updateTreasury(address payable _treasury) external;
    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) external;
    function addCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32  _reserveRatio, uint256 _slippage, uint256 _rate, uint256 _floor) external;
    function reAddCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32  _reserveRatio, uint256 _slippage) external;
    function removeCollateralToken(address _collateral) external;
    function updateCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio, uint256 _slippage) external;
    function openBuyOrder(address _collateral, uint256 _value) external;
    function openSellOrder(address _collateral, uint256 _amount) external;
    function claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) external;
    function claimSellOrder(address _seller, uint256 _batchId, address _collateral) external;
    function claimCancelledBuyOrder(address _buyer, uint256 _batchId, address _collateral) external;
    function claimCancelledSellOrder(address _seller, uint256 _batchId, address _collateral) external;

    /************************************/
    /****** TAP SPECIFIC INTERFACE ******/
    /************************************/
    function updateBeneficiary(address payable _beneficiary) external;
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external;
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external;
    function removeTappedToken(address _token) external;
    function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external;
    function updateTappedAmount(address _token) external;
    function withdrawTap(address _collateral) external;
    function getMaximumWithdrawal(address _token) external view returns (uint256);
}

/**
* ENGA Federation EngalandBase.
* @author Mehdikovic
* Date created: 2022.06.18
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract EngalandBase is AccessControl {
    string private constant ERROR_CONTRACT_HAS_BEEN_INITIALIZED_BEFORE = "ERROR_CONTRACT_HAS_BEEN_INITIALIZED_BEFORE";
    string private constant ERROR_ONLY_CONTROLLER_CAN_CALL             = "ERROR_ONLY_CONTROLLER_CAN_CALL";

    bool private _isInitialized = false;

    constructor(address _controller) {
        _grantRole(DEFAULT_ADMIN_ROLE, _controller);
    }

    function _initialize() internal {
        require(!_isInitialized, ERROR_CONTRACT_HAS_BEEN_INITIALIZED_BEFORE);
        _isInitialized = true;
    }

    modifier onlyInitialized {
        require(_isInitialized);
        _;
    }

    modifier onlyInitializer {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), ERROR_ONLY_CONTROLLER_CAN_CALL);
        _;
    }

    function isInitialized() external view returns (bool) {
        return _isInitialized;
    }
}

/**
* ENGA Federation IEngaToken Interface.
* @author Aragon.org, Mehdikovic
* Date created: 2022.06.20
* Github: mehdikovic
* SPDX-License-Identifier: AGPL-3.0
*/

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IEIP2612 } from "../fundraising/IEIP2612.sol";

interface IEngaToken is IERC20, IEIP2612 {
    event Minted(address indexed receiver, uint256 amount);
    event Burned(address indexed burner, uint256 amount);

    function mint(address _receiver, uint256 _amount) external;
    function burn(address _burner, uint256 _amount) external;

    //EIP-223 LOGIC
    function transfer(address _to, uint256 _amount, bytes calldata _data) external returns (bool);

    //EIP-2612 LOGIC
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    // solhint-disable func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
* ENGA Federation Token Manager Interface.
* @author Mehdikovic
* Date created: 2022.03.03
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface ITokenManager {
    function initialize(address _stakeHolder,address _seedSale) external;
    function closeVestingProcess() external;
    function mint(address _receiver, uint256 _amount) external;
    function burn(address _burner, uint256 _amount) external;
    function createVesting(address _beneficiary, address _vestingCreator, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _end, bool _revocable) external returns (bytes32 vestingId);
    function revoke(bytes32 vestingId) external;
    function release(bytes32 vestingId) external;
    function withdraw(address _token, address _receiver, uint256 _amount) external;
    function getVestingOwner(bytes32 vestingId) external view returns(address);
    function isVestingClosed() external view returns(bool);
    function getEngaToken() external view returns(address);
}

/**
* ENGA Federation Market Maker Interface.
* @author Mehdikovic
* Date created: 2022.03.08
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface IMarketMaker {
    function initialize(uint256  _batchBlocks, uint256  _buyFeePct, uint256  _sellFeePct) external;
    function open() external;
    function suspend(bool _value) external;
    function updateBancorFormula(address _bancor) external;
    function updateTreasury(address _treasury) external;
    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) external;
    function addCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio, uint256 _slippage) external;
    function removeCollateralToken(address _collateral) external;
    function updateCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio, uint256 _slippage) external;
    function openBuyOrder(address _buyer, address _collateral, uint256 _value) external;
    function openSellOrder(address _seller, address _collateral, uint256 _amount) external;
    function claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) external;
    function claimSellOrder(address _seller, uint256 _batchId, address _collateral) external;
    function claimCancelledBuyOrder(address _buyer, uint256 _batchId, address _collateral) external;
    function claimCancelledSellOrder(address _seller, uint256 _batchId, address _collateral) external;
    function collateralIsWhitelisted(address _collateral) external view returns (bool);
    function collateralsToBeClaimed(address _collateral) external view returns(uint256);
}

/**
* ENGA Federation BancorFormula Interface.
* @author Aragon.org, Mehdikovic
* Date created: 2022.03.09
* Github: mehdikovic
* SPDX-License-Identifier: AGPL-3.0
*/

pragma solidity ^0.8.0;

interface IBancor {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) external view returns (uint256);
}

/**
* ENGA Federation Tap Interface.
* @author Mehdikovic
* Date created: 2022.03.08
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface ITap {
    function initialize(uint256 _batchBlocks, uint256 _maximumTapRateIncreasePct, uint256 _maximumTapFloorDecreasePct) external;
    function updateBeneficiary(address _beneficiary) external;
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external;
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external;
    function addTappedToken(address _token, uint256 _rate, uint256 _floor) external;
    function removeTappedToken(address _token) external;
    function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external;
    function resetTappedToken(address _token) external;
    function updateTappedAmount(address _token) external;
    function withdraw(address _token) external;
    function getMaximumWithdrawal(address _token) external view returns (uint256);
    function tokenIsTapped(address _token) external view returns(bool);
}

/**
* ENGA Federation IVaultERC20.
* @author Mehdikovic
* Date created: 2022.03.08
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface IVaultERC20 {
    function balanceERC20(address _token) external view returns (uint256);
    function depositERC20(address _token, uint256 _value) external payable;
    function transferERC20(address _token, address _to, uint256 _value) external;
}

/**
* ENGA Federation IKycAuthorization contract.
* @author Mehdikovic
* Date created: 2022.03.23
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;


interface IKycAuthorization {
    function enableKyc() external;
    function disableKyc() external;
    function addKycUser(address _user) external;
    function removeKycUser(address _user) external;
    function addKycUserBatch(address[] memory _user) external;
    function removeKycUserBatch(address[] memory _user) external;
    function getKycOfUser(address _user) external view returns (bool isKyc);
}

/**
* ENGA Federation PreSale Interface.
* @author Mehdikovic
* Date created: 2022.03.06
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

enum SaleState {
    Pending,     // presale is idle and pending to be started
    Funding,     // presale has started and contributors can purchase tokens
    Refunding,   // presale has not reached goal within period and contributors can claim refunds
    GoalReached, // presale has reached goal within period and trading is ready to be open
    Closed       // presale has reached goal within period, has been closed and trading has been open
}

interface IPreSale {

    function openByDate(uint256 _openDate) external;
    function openNow() external;
    function close() external;
    function state() external view returns (SaleState);
    function getController() external view returns(address);
    function contribute(address _contributor, uint256 _value) external;
    function refund(address _contributor, bytes32 _vestedPurchaseId) external;
    function contributionToTokens(uint256 _contribution) external view returns (uint256);
    function tokenToContributions(uint256 _engaToken) external view returns (uint256);
}

/**
* ENGA Federation Accress Control contract.
* @author Mehdikovic
* Date created: 2022.03.01
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import {MultisigOwner} from "./MultisigOwner.sol";


abstract contract EngalandAccessControlEnumerable is MultisigOwner, AccessControlEnumerable {
    
    constructor(address _owner) MultisigOwner(_owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    modifier onlyMultisigOrRole(bytes32 _role) {
        require(_msgSender() == owner || hasRole(_role,_msgSender()), "ONLY MULTI-SIG OR SPECIFIC ROLE HAS ACCESS");
        _;
    }

    // CALLBACK FROM MultisigOwner
    function _afterMultisigChanged(address _prevOwner, address _newOwner) internal virtual override {
        _revokeRole(DEFAULT_ADMIN_ROLE, _prevOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
    }
}

abstract contract EngalandAccessControl is MultisigOwner, AccessControl {
    
    constructor(address _owner) MultisigOwner(_owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    modifier onlyMultisigOrRole(bytes32 _role) {
        require(_msgSender() == owner || hasRole(_role,_msgSender()), "ONLY MULTI-SIG OR SPECIFIC ROLE HAS ACCESS");
        _;
    }

    // CALLBACK FROM MultisigOwner
    function _afterMultisigChanged(address _prevOwner, address _newOwner) internal virtual override {
        _revokeRole(DEFAULT_ADMIN_ROLE, _prevOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
    }
}

/**
* ENGA Federation Utility contract.
* @author Mehdikovic
* Date created: 2022.03.01
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

library Utils {
    function getSig(string memory _fullSignature) internal pure returns(bytes4 _sig) {
        _sig = bytes4(keccak256(bytes(_fullSignature)));
    }

    function transferNativeToken(address _to, uint256 _value) internal returns (bool) {
        // solhint-disable avoid-low-level-calls
        (bool sent, ) = payable(_to).call{value: _value}("");
        return sent;
    }

    function enforceHasContractCode(address _target, string memory _errorMsg) internal view {
        require(_target != address(0), _errorMsg);

        uint256 size;
        // solhint-disable-next-line
        assembly { size := extcodesize(_target) }
        require(size > 0, _errorMsg);
    }

    function enforceValidAddress(address _target, string memory _errorMsg) internal pure {
        require(_target != address(0), _errorMsg);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

/**
* ENGA Federation EIP2621, ERC20 Extension.
* @author Mehdikovic
* Date created: 2022.04.27
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface IEIP2612 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint);
    // solhint-disable func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
}

/**
* ENGA Federation Multisig.
* @author Mehdikovic
* Date created: 2022.02.15
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;


import { IERC173 } from "../interfaces/access/IERC173.sol";
import { Utils } from "../lib/Utils.sol";

abstract contract Owner is IERC173 {
    string constant internal ERROR_INVALID_ADDRESS                             = "ERROR_INVALID_ADDRESS";
    string constant internal ERROR_ONLY_MULTISIG_HAS_ACCESS                    = "ERROR_ONLY_MULTISIG_HAS_ACCESS";
    string constant internal ERROR_NEW_MULTISIG_MUST_BE_DIFFERENT_FROM_OLD_ONE = "ERROR_NEW_MULTISIG_MUST_BE_DIFFERENT_FROM_OLD_ONE";

    /// @notice multisig pointer as the owner
    address public owner;

    event OwnershipChanged(address indexed prevOwner, address indexed newOwner);

    /* STATE MODIFIERS */

    function transferOwnership(address _newOwner) external onlyMultisig {
        require(_newOwner != owner, ERROR_NEW_MULTISIG_MUST_BE_DIFFERENT_FROM_OLD_ONE);
        Utils.enforceHasContractCode(_newOwner, ERROR_INVALID_ADDRESS);

        _transferOwnership(_newOwner);
    }

    /* MODIFIERS */

    modifier onlyMultisig {
        require(msg.sender == owner, ERROR_ONLY_MULTISIG_HAS_ACCESS);
        _;
    }


    /* INTERNALS */

    //solhint-disable no-empty-blocks
    function _afterMultisigChanged(address _prevOwner, address _newOwner) internal virtual {}

    function _transferOwnership(address _newOwner) internal {
        address old = owner;
        owner = _newOwner;
        _afterMultisigChanged(old, _newOwner);
        
        emit OwnershipChanged(old, _newOwner);
    }
}

abstract contract MultisigOwner is Owner {
    constructor(address _owner) {
        Utils.enforceHasContractCode(_owner, ERROR_INVALID_ADDRESS);
        owner = _owner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

/**
* ENGA Federation IERC173 contract.
* @author Mehdikovic
* Date created: 2022.04.03
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;


interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}