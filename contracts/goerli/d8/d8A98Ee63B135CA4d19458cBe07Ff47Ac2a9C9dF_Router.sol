// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IRouter} from "./interfaces/IRouter.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IVaultLiquid} from "./interfaces/IVaultLiquid.sol";
import {IVaultLocked} from "./interfaces/IVaultLocked.sol";
import {IRegistrar} from "./interfaces/IRegistrar.sol";
import {StringToAddress} from "./lib/StringAddressUtils.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AxelarExecutable} from "./axelar/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

contract Router is IRouter, AxelarExecutable, OwnableUpgradeable {
    IRegistrar public registrar;
    IAxelarGasService public gasReceiver;

    /*///////////////////////////////////////////////
                        PROXY INIT
    *////////////////////////////////////////////////

    function initialize(
        address _gateway,
        address _gasReceiver,
        address _registrar
    ) public initializer {
        registrar = IRegistrar(_registrar);
        gasReceiver = IAxelarGasService(_gasReceiver);
        __AxelarExecutable_init_unchained(_gateway);
        __Ownable_init_unchained();
    }

    /*///////////////////////////////////////////////
                    MODIFIERS
    *////////////////////////////////////////////////

    modifier onlyOneAccount(VaultActionData memory _action) {
        require(_action.accountIds.length == 1, "Only one account allowed");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    modifier validateDeposit(
        VaultActionData memory action, 
        string calldata tokenSymbol, 
        uint256 amount
        ) 
    {
        // Only one account accepted for deposit calls
        require(action.accountIds.length == 1, "Only one account allowed");
        // deposit only 
        require(action.selector == IVault.deposit.selector, "Only deposit accepts tokens");
        // token fwd is token expected 
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);
        require(tokenAddress == action.token, "Token mismatch");
        // amt fwd equal expected amt 
        require(amount == (action.liqAmt + action.lockAmt),"Amount mismatch");
        // check that at least one vault is expected to receive a deposit 
        require(action.lockAmt > 0 || action.liqAmt > 0,"No vault deposit specified");
        // check that token is accepted by angel protocol
        require(registrar.isTokenAccepted(tokenAddress),"Token not accepted");
        // Get parameters from registrar if approved
        require(
            registrar.getStrategyApprovalState(action.strategyId) == IRegistrar.StrategyApprovalState.APPROVED,
            "Strategy not approved");
        _;
    }

    modifier validateCall(
        VaultActionData memory action
    )
    {
        require(
            (registrar.getStrategyApprovalState(action.strategyId) == IRegistrar.StrategyApprovalState.APPROVED) || 
            registrar.getStrategyApprovalState(action.strategyId) == IRegistrar.StrategyApprovalState.WITHDRAW_ONLY,
            "Strategy not approved");
        _;
    }

    /*///////////////////////////////////////////////
                    ANGEL PROTOCOL ROUTER
    *////////////////////////////////////////////////

    function _callSwitch(
        IRegistrar.StrategyParams memory _params,
        VaultActionData memory _action
    ) 
        internal 
        override 
        validateCall(_action)
    {
        // REDEEM
        if (_action.selector == IVault.redeem.selector) {
            _redeem(_params, _action);
        }
        // REDEEM ALL
        else if (_action.selector == IVault.redeemAll.selector) {
            _redeemAll(_params, _action);
        }
        // HARVEST
        else if (_action.selector == IVault.harvest.selector) {
            _harvest(_params, _action);
        }
        // INVALID SELCTOR
        else {
            revert("Invalid function selector provided");
        }
    }

    // Vault action::Deposit
    /// @notice Deposit into the associated liquid or locked vaults 
    /// @dev onlySelf restricted public method to enable try/catch in caller
    function deposit(
        IRegistrar.StrategyParams memory params,
        VaultActionData memory action,
        string calldata tokenSymbol,
        uint256 amount
    ) 
        public 
        onlySelf 
        validateDeposit(action, tokenSymbol, amount)
    {

        if(action.lockAmt > 0) {
            // Send tokens to locked vault and call deposit
            require(IERC20Metadata(action.token).transfer(params.Locked.vaultAddr, action.lockAmt));
            IVaultLocked lockedVault = IVaultLocked(params.Locked.vaultAddr);
            lockedVault.deposit(
                action.accountIds[0],
                action.token,
                action.lockAmt
            );
        }
   
        if(action.liqAmt >  0) {
            // Send tokens to liquid vault and call deposit 
            require(IERC20Metadata(action.token).transfer(params.Liquid.vaultAddr, action.liqAmt));
            IVaultLiquid liquidVault = IVaultLiquid(params.Liquid.vaultAddr);
            liquidVault.deposit(
                action.accountIds[0],
                action.token,
                action.liqAmt
            );
        }
    }

    // Vault action::Redeem
    function _redeem(
        IRegistrar.StrategyParams memory _params,
        VaultActionData memory _action
    ) 
        internal 
        onlyOneAccount(_action) 
    {
        IVaultLocked lockedVault = IVaultLocked(_params.Locked.vaultAddr);
        IVaultLiquid liquidVault = IVaultLiquid(_params.Liquid.vaultAddr);

        // Redeem tokens from vaults which sends them from the vault to this contract
        uint256 _redeemedLockAmt = lockedVault.redeem(
            _action.accountIds[0],
            _action.token,
            _action.lockAmt
        );
        require(IERC20Metadata(_action.token).transferFrom(_params.Locked.vaultAddr, address(this), _redeemedLockAmt));

        uint256 _redeemedLiqAmt = liquidVault.redeem(
            _action.accountIds[0],
            _action.token,
            _action.liqAmt
        );
        require(IERC20Metadata(_action.token).transferFrom(_params.Liquid.vaultAddr, address(this), _redeemedLiqAmt));

        // Pack and send the tokens back through GMP 
        uint256 _redeemedAmt = _redeemedLockAmt + _redeemedLiqAmt;
        _action.lockAmt = _redeemedLockAmt;
        _action.liqAmt = _redeemedLiqAmt;
        _prepareAndSendTokens(_action, _redeemedAmt);
        emit Redemption(_action, _redeemedAmt);
    }

    // Vault action::RedeemAll
    // @todo redemption amts need to affect _action data 
        function _redeemAll(
        IRegistrar.StrategyParams memory _params,
        VaultActionData memory _action
    ) internal onlyOneAccount(_action) {
        IVaultLocked lockedVault = IVaultLocked(_params.Locked.vaultAddr);
        IVaultLiquid liquidVault = IVaultLiquid(_params.Liquid.vaultAddr);

        // Redeem tokens from vaults and txfer them to the Router
        uint256 _redeemedLockAmt;
        if(_action.lockAmt > 0) {
            _redeemedLockAmt = lockedVault.redeemAll(
                _action.accountIds[0]);
            require(IERC20Metadata(_action.token)
                .transferFrom(_params.Locked.vaultAddr, address(this), _redeemedLockAmt));
            _action.lockAmt = _redeemedLockAmt;
        }

        uint256 _redeemedLiqAmt;
        if(_action.liqAmt > 0) {
            _redeemedLiqAmt = liquidVault.redeemAll(
                _action.accountIds[0]);
            require(IERC20Metadata(_action.token)
                .transferFrom(_params.Liquid.vaultAddr, address(this), _redeemedLiqAmt));
            _action.liqAmt = _redeemedLiqAmt;
        }

        // Pack and send the tokens back through GMP 
        uint256 _redeemedAmt = _redeemedLockAmt + _redeemedLiqAmt; 
        _prepareAndSendTokens(_action, _redeemedAmt);
        emit Redemption(_action, _redeemedAmt);
    }


    // Vault action::Harvest
    // @todo redemption amts need to affect _action data 
    function _harvest(
        IRegistrar.StrategyParams memory _params,
        VaultActionData memory _action
    ) internal {
        IVaultLiquid liquidVault = IVaultLiquid(_params.Liquid.vaultAddr);
        IVaultLocked lockedVault = IVaultLocked(_params.Locked.vaultAddr);
        liquidVault.harvest(_action.accountIds);
        lockedVault.harvest(_action.accountIds);
        emit Harvest(_action);
    }

    /*////////////////////////////////////////////////
                        AXELAR IMPL.
    */////////////////////////////////////////////////

    modifier onlyPrimaryChain(string calldata _sourceChain) {
        IRegistrar.AngelProtocolParams memory APParams = registrar
            .getAngelProtocolParams();
        require(
            keccak256(bytes(_sourceChain)) ==
                keccak256(bytes(APParams.primaryChain)),
            "Unauthorized Call"
        );
        _;
    }

    modifier onlyPrimaryRouter(string calldata _sourceAddress) {
        IRegistrar.AngelProtocolParams memory APParams = registrar
            .getAngelProtocolParams();
        require(
            StringToAddress.toAddress(_sourceAddress) ==
                StringToAddress.toAddress(APParams.primaryChainRouter),
            "Unauthorized Call"
        );
        _;
    }

    function _prepareAndSendTokens(
        VaultActionData memory _action, 
        uint256 _sendAmt
        ) internal {

        // Pack the tokens and calldata for bridging back out over GMP

        IRegistrar.AngelProtocolParams memory apParams = registrar
            .getAngelProtocolParams();
        

        // Prepare gas
        uint256 gasFee = registrar.getGasByToken(_action.token);
        require(_sendAmt > gasFee, "Send amount does not cover gas");
        uint256 amtLessGasFee = _sendAmt - gasFee;

        // Split gas proportionally between liquid and lock amts 
        uint256 PRECISION = 10**6;
        uint256 liqGas = gasFee * (_action.liqAmt * PRECISION / _sendAmt) / PRECISION; 
        uint256 lockGas =  gasFee - liqGas;
        _action.liqAmt -= liqGas;
        _action.lockAmt -= lockGas;

        bytes memory payload = _packCallData(_action);
        try this.sendTokens(
                apParams.primaryChain,
                apParams.primaryChainRouter,
                payload,
                IERC20Metadata(_action.token).symbol(),
                amtLessGasFee,
                _action.token,
                gasFee
            ) {
                emit TokensSent(_action, amtLessGasFee);
        }
        catch Error(string memory reason) {
            emit LogError(_action, reason);
            IERC20Metadata(_action.token).transfer(apParams.refundAddr, _sendAmt);
            emit FallbackRefund(_action, _sendAmt);
        }
        catch (bytes memory data) {
            emit LogErrorBytes(_action, data);
            IERC20Metadata(_action.token).transfer(apParams.refundAddr, _sendAmt);
            emit FallbackRefund(_action, _sendAmt);
        }
    }

    function sendTokens(
        string memory destinationChain,
        string memory destinationAddress,
        bytes memory payload,
        string memory symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmt
    ) 
        public 
        onlySelf 
    {
        address tokenAddress = gateway.tokenAddresses(symbol);
        require(IERC20Metadata(tokenAddress).approve(address(gateway), amount));
        require(IERC20Metadata(gasToken).approve(address(gasReceiver), gasFeeAmt));

        IRegistrar.AngelProtocolParams memory apParams = registrar
            .getAngelProtocolParams();

        gasReceiver.payGasForContractCallWithToken(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount,
            gasToken,
            gasFeeAmt,
            apParams.protocolTaxCollector
        );

        gateway.callContractWithToken(
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount
        );
    }

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    )
        internal
        override
        onlyPrimaryChain(sourceChain)
        onlyPrimaryRouter(sourceAddress)
    {
        
        // decode payload
        VaultActionData memory action = _unpackCalldata(payload);
        IRegistrar.StrategyParams memory params = registrar
            .getStrategyParamsById(action.strategyId);

        // Leverage this.call() to enable try/catch logic 
        try this.deposit(params, action, tokenSymbol, amount) {
            emit Deposit(action);
        }
        catch Error(string memory reason) {
            emit LogError(action, reason);
            _prepareAndSendTokens(action, amount);
        }
        catch (bytes memory data) {
            emit LogErrorBytes(action, data);
            _prepareAndSendTokens(action, amount);
        }
    }
    
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    )
        internal
        override
        onlyPrimaryChain(sourceChain)
        onlyPrimaryRouter(sourceAddress)
    {
        // decode payload
        VaultActionData memory action = _unpackCalldata(payload);
        IRegistrar.StrategyParams memory params = registrar
            .getStrategyParamsById(action.strategyId);

        // Switch for calling appropriate vault/method
        _callSwitch(params, action);
    }
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IAxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import {IVault} from "./IVault.sol";
import {IRegistrar} from "./IRegistrar.sol";

abstract contract IRouter is IAxelarExecutable {
    /*////////////////////////////////////////////////
                        EVENTS
    */////////////////////////////////////////////////

    event TokensSent(VaultActionData action, uint256 amount);
    event FallbackRefund(VaultActionData action, uint256 amount);
    event Deposit(VaultActionData action);
    event Redemption(VaultActionData action, uint256 amount);
    event Harvest(VaultActionData action);
    event LogError(VaultActionData action, string message);
    event LogErrorBytes(VaultActionData action, bytes data);

    /*////////////////////////////////////////////////
                    CUSTOM TYPES
    */////////////////////////////////////////////////

    /// @notice Gerneric AP Vault action data that can be packed and sent through the GMP
    /// @dev Data will arrive from the GMP encoded as a string of bytes. For internal methods/processing,
    /// we can restructure it to look like VaultActionData to improve readability.
    /// @param strategyId The 4 byte truncated keccak256 hash of the strategy name, i.e. bytes4(keccak256("Goldfinch"))
    /// @param selector The Vault method that should be called
    /// @param accountId The endowment uid
    /// @param token The token (if any) that was forwarded along with the calldata packet by GMP
    /// @param lockAmt The amount of said token that is intended to interact with the locked vault
    /// @param liqAmt The amount of said token that is intended to interact with the liquid vault
    struct VaultActionData {
        bytes4 strategyId;
        bytes4 selector;
        uint32[] accountIds;
        address token;
        uint256 lockAmt;
        uint256 liqAmt;
    }


    /*////////////////////////////////////////////////
                        METHODS
    */////////////////////////////////////////////////

    // Internal data packing methods
    function _unpackCalldata(bytes memory _calldata)
        internal
        virtual
        returns (VaultActionData memory)
    {
        (
            bytes4 strategyId,
            bytes4 selector,
            uint32[] memory accountIds,
            address token,
            uint256 lockAmt,
            uint256 liqAmt
        ) = abi.decode(
                _calldata,
                (bytes4, bytes4, uint32[], address, uint256, uint256)
            );

        return
            VaultActionData(
                strategyId,
                selector,
                accountIds,
                token,
                lockAmt,
                liqAmt
            );
    }

    function _packCallData(VaultActionData memory _calldata)
        internal
        virtual
        returns (bytes memory)
    {
        return
            abi.encode(
                _calldata.strategyId,
                _calldata.selector,
                _calldata.accountIds,
                _calldata.token,
                _calldata.lockAmt,
                _calldata.liqAmt
            );
    }

    function _callSwitch(
        IRegistrar.StrategyParams memory _params,
        VaultActionData memory _action
    ) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

abstract contract IVault {
    
    /// @notice Angel Protocol Vault Type 
    /// @dev Vaults have different behavior depending on type. Specifically access to redemptions and 
    /// principle balance
    enum VaultType {
        LOCKED,
        LIQUID
    }

    /// @notice Event emited on each Deposit call
    /// @dev Upon deposit, emit this event. Index the account and staking contract for analytics 
    event DepositMade(
        uint32 indexed accountId, 
        VaultType vaultType, 
        address tokenDeposited, 
        uint256 amtDeposited); 

    /// @notice Event emited on each Redemption call 
    /// @dev Upon redemption, emit this event. Index the account and staking contract for analytics 
    event Redemption(
        uint32 indexed accountId, 
        VaultType vaultType, 
        address tokenRedeemed, 
        uint256 amtRedeemed);

    /// @notice Event emited on each Harvest call
    /// @dev Upon harvest, emit this event. Index the accounts harvested for. 
    /// Rewards that are re-staked or otherwise reinvested will call other methods which will emit events
    /// with specific yield/value details
    /// @param accountIds a list of the Accounts harvested for
    event Harvest(uint32[] indexed accountIds);

    /*////////////////////////////////////////////////
                    EXTERNAL METHODS
    */////////////////////////////////////////////////

    /// @notice returns the vault type
    /// @dev a vault must declare its Type upon initialization/construction 
    function getVaultType() external view virtual returns (VaultType);

    /// @notice deposit tokens into vault position of specified Account 
    /// @dev the deposit method allows the Vault contract to create or add to an existing 
    /// position for the specified Account. In the case that multiple different tokens can be deposited,
    /// the method requires the deposit token address and amount. The transfer of tokens to the Vault 
    /// contract must occur before the deposit method is called.   
    /// @param accountId a unique Id for each Angel Protocol account
    /// @param token the deposited token
    /// @param amt the amount of the deposited token 
    function deposit(uint32 accountId, address token, uint256 amt) payable external virtual;

    /// @notice redeem value from the vault contract
    /// @dev allows an Account to redeem from its staked value. The behavior is different dependent on VaultType.
    /// Before returning the redemption amt, the vault must approve the Router to spend the tokens. 
    /// @param accountId a unique Id for each Angel Protocol account
    /// @param token the deposited token
    /// @param amt the amount of the deposited token 
    /// @return redemptionAmt returns the number of tokens redeemed by the call; this may differ from 
    /// the called `amt` due to slippage/trading/fees
    function redeem(uint32 accountId, address token, uint256 amt) payable external virtual returns (uint256);

    /// @notice redeem all of the value from the vault contract
    /// @dev allows an Account to redeem all of its staked value. Good for rebasing tokens wherein the value isn't
    /// known explicitly. Before returning the redemption amt, the vault must approve the Router to spend the tokens.
    /// @param accountId a unique Id for each Angel Protocol account
    /// @return redemptionAmt returns the number of tokens redeemed by the call
    function redeemAll(uint32 accountId) payable external virtual returns (uint256); 

    /// @notice restricted method for harvesting accrued rewards 
    /// @dev Claim reward tokens accumulated to the staked value. The underlying behavior will vary depending 
    /// on the target yield strategy and VaultType. Only callable by an Angel Protocol Keeper
    /// @param accountIds Used to specify which accounts to call harvest against. Structured so that this can
    /// be called in batches to avoid running out of gas.
    function harvest(uint32[] calldata accountIds) external virtual;

    /*////////////////////////////////////////////////
                INTERNAL HELPER METHODS
    */////////////////////////////////////////////////

    /// @notice nternal method for validating that calls came from the approved AP router 
    /// @dev The registrar will hold a record of the approved Router address. This method must implement a method of 
    /// checking that the msg.sender == ApprovedRouter
    function _isApprovedRouter() internal virtual returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import { IVault } from "./IVault.sol";

abstract contract IVaultLiquid is IVault {

}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import { IVault } from "./IVault.sol";

abstract contract IVaultLocked is IVault {

}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import { IVault } from "./IVault.sol";
 
interface IRegistrar {

    /*////////////////////////////////////////////////
                        EVENTS
    */////////////////////////////////////////////////
    event RebalanceParamsChanged(RebalanceParams newRebalanceParams);
    event AngelProtocolParamsChanged(
        AngelProtocolParams newAngelProtocolParams
    );
    event TokenAcceptanceChanged(address indexed tokenAddr, bool isAccepted);
    event StrategyApprovalChanged(bytes4 indexed _strategyId, StrategyApprovalState _approvalState);
    event StrategyParamsChanged(
        bytes4 indexed _strategyId,
        address indexed _lockAddr,
        address indexed _liqAddr,
        StrategyApprovalState _approvalState
    );
    event GasFeeUpdated(address indexed _tokenAddr, uint256 _gasFee); 


    /*////////////////////////////////////////////////
                        CUSTOM TYPES
    */////////////////////////////////////////////////
    struct RebalanceParams {
        bool rebalanceLiquidProfits;
        uint32 lockedRebalanceToLiquid;
        uint32 interestDistribution;
        bool lockedPrincipleToLiquid;
        uint32 principleDistribution;
        uint32 basis;
    }

    struct AngelProtocolParams {
        uint32 protocolTaxRate;
        uint32 protocolTaxBasis;
        address protocolTaxCollector;
        string primaryChain;
        string primaryChainRouter;
        address routerAddr;
        address refundAddr;
    }

    enum StrategyApprovalState {
        NOT_APPROVED,
        APPROVED,
        WITHDRAW_ONLY,
        DEPRECATED
    }

    // @TODO change to ENUM for approval
    struct StrategyParams {
        StrategyApprovalState approvalState;
        VaultParams Locked;
        VaultParams Liquid;
    }

    struct VaultParams {
        IVault.VaultType Type;
        address vaultAddr;
    }

    /*////////////////////////////////////////////////
                    EXTERNAL METHODS
    */////////////////////////////////////////////////

    // View methods for returning stored params
    function getRebalanceParams()
        external
        view
        returns (RebalanceParams memory);

    function getAngelProtocolParams()
        external
        view
        returns (AngelProtocolParams memory);

    function getStrategyParamsById(bytes4 _strategyId)
        external
        view
        returns (StrategyParams memory);

    function isTokenAccepted(address _tokenAddr) external view returns (bool);

    function getGasByToken(address _tokenAddr) external view returns (uint256);

    function getStrategyApprovalState(bytes4 _strategyId)
        external
        view
        returns (StrategyApprovalState);
    
    // Setter meothods for granular changes to specific params
    function setRebalanceParams(RebalanceParams calldata _rebalanceParams)
        external;

    function setAngelProtocolParams(
        AngelProtocolParams calldata _angelProtocolParams
    ) external;

    /// @notice Change whether a strategy is approved
    /// @dev Set the approval bool for a specified strategyId.
    /// @param _strategyId a uid for each strategy set by:
    /// bytes4(keccak256("StrategyName"))
    function setStrategyApprovalState(bytes4 _strategyId, StrategyApprovalState _approvalState)
        external;

    /// @notice Change which pair of vault addresses a strategy points to
    /// @dev Set the approval bool and both locked/liq vault addrs for a specified strategyId.
    /// @param _strategyId a uid for each strategy set by:
    /// bytes4(keccak256("StrategyName"))
    /// @param _liqAddr address to a comptaible Liquid type Vault
    /// @param _lockAddr address to a compatible Locked type Vault
    function setStrategyParams(
        bytes4 _strategyId,
        address _liqAddr,
        address _lockAddr,
        StrategyApprovalState _approvalState
    ) external;

    function setTokenAccepted(address _tokenAddr, bool _isAccepted) external;

    function setGasByToken(address _tokenAddr, uint256 _gasFee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }
        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        uint256 length = addressBytes.length;
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(2 + addressBytes.length * 2);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < length; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }
        return string(stringBytes);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// Modifications by @stevieraykatz to make compatible with OZ Upgradable Proxy 

pragma solidity >=0.8.0;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AxelarExecutable is IAxelarExecutable, Initializable {
    IAxelarGateway public gateway;

    // We want this to be intializeable by an OZ upgradable pattern so move the constructor logic to _init_ methods 
    function __AxelarExecutable_init(address gateway_) internal onlyInitializing {
        __AxelarExecutable_init_unchained(gateway_);
    }

    function __AxelarExecutable_init_unchained(address gateway_) internal onlyInitializing {
        if (gateway_ == address(0)) revert InvalidAddress();
        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error TransferFailed();
    error InvalidAddress();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(address payable receiver, address[] calldata tokens) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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