// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import {IIndexToken} from "./IIndexToken.sol";

interface IBasicIssuanceModule {
    function getRequiredComponentUnitsForIssue(
        IIndexToken _indexToken,
        uint256 _quantity
    ) external view returns (address[] memory, uint256[] memory);

    function issue(
        IIndexToken _indexToken,
        uint256 _quantity,
        address _to
    ) external;

    function redeem(
        IIndexToken _indexToken,
        uint256 _quantity,
        address _to
    ) external;
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IIndexToken
 *
 * Interface for operating with IndexTokens.
 */
interface IIndexToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a IndexToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a IndexToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function indexManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IBasicIssuanceModule } from "../interfaces/IBasicIssuanceModule.sol";
import { IDebtIssuanceModule } from "../interfaces/IDebtIssuanceModule.sol";
import { IController } from "../interfaces/IController.sol";
import { IIndexToken } from "../interfaces/IIndexToken.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";


contract ExchangeIssuanceZeroEx is Ownable, ReentrancyGuard {

    using Address for address payable;
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IIndexToken;

    struct IssuanceModuleData {
        bool isAllowed;
        bool isDebtIssuanceModule;
    }

    /* ============ Constants ============== */

    // Placeholder address to identify ETH where it is treated as if it was an ERC20 token
    address constant public ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ============ State Variables ============ */

    address public immutable WETH;
    IController public immutable indexController;
    address public immutable swapTarget;

    /* ============ Events ============ */

    event ExchangeIssue(
        address indexed _recipient,     // The recipient address of the issued IndexTokens
        IIndexToken indexed _indexToken,// The issued IndexToken
        IERC20 indexed _inputToken,     // The address of the input asset(ERC20/ETH) used to issue the IndexTokens
        uint256 _amountInputToken,      // The amount of input tokens used for issuance
        uint256 _amountSetIssued        // The amount of IndexTokens received by the recipient
    );

    event ExchangeRedeem(
        address indexed _recipient,     // The recipient adress of the output tokens obtained for redemption
        IIndexToken indexed _indexToken,    // The redeemed IndexToken
        IERC20 indexed _outputToken,    // The address of output asset(ERC20/ETH) received by the recipient
        uint256 _amountSetRedeemed,     // The amount of IndexTokens redeemed for output tokens
        uint256 _amountOutputToken      // The amount of output tokens received by the recipient
    );

    /* ============ Modifiers ============ */

    modifier isValidModule(address _issuanceModule) {
        require(indexController.isModule(_issuanceModule), "ExchangeIssuance: INVALID ISSUANCE MODULE");
         _;
    }

    constructor(
        address _weth,
        IController _indexController,
        address _swapTarget
    )
        public
    {
        indexController = _indexController;

        WETH = _weth;
        swapTarget = _swapTarget;
    }

    /* ============ External Functions ============ */

    /**
     * Withdraw slippage to selected address
     *
     * @param _tokens    Addresses of tokens to withdraw, specifiy ETH_ADDRESS to withdraw ETH
     * @param _to        Address to send the tokens to
     */
    function withdrawTokens(IERC20[] calldata _tokens, address payable _to) external onlyOwner payable {
        for(uint256 i = 0; i < _tokens.length; i++) {
            if(address(_tokens[i]) == ETH_ADDRESS){
                _to.sendValue(address(this).balance);
            }
            else{
                _tokens[i].safeTransfer(_to, _tokens[i].balanceOf(address(this)));
            }
        }
    }

    receive() external payable {
        // required for weth.withdraw() to work properly
        require(msg.sender == WETH, "ExchangeIssuance: Direct deposits not allowed");
    }

    /* ============ Public Functions ============ */


    /**
     * Runs all the necessary approval functions required for a given ERC20 token.
     * This function can be called when a new token is added to a IndexToken during a
     * rebalance.
     *
     * @param _token    Address of the token which needs approval
     * @param _spender  Address of the spender which will be approved to spend token. (Must be a whitlisted issuance module)
     */
    function approveToken(IERC20 _token, address _spender) public isValidModule(_spender) {
        _safeApprove(_token, _spender, type(uint256).max);
    }

    /**
     * Runs all the necessary approval functions required for a list of ERC20 tokens.
     *
     * @param _tokens    Addresses of the tokens which need approval
     * @param _spender   Address of the spender which will be approved to spend token. (Must be a whitlisted issuance module)
     */
    function approveTokens(IERC20[] calldata _tokens, address _spender) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            approveToken(_tokens[i], _spender);
        }
    }

    /**
     * Runs all the necessary approval functions required before issuing
     * or redeeming a IndexToken. This function need to be called only once before the first time
     * this smart contract is used on any particular IndexToken.
     *
     * @param _indexToken          Address of the IndexToken being initialized
     * @param _issuanceModule    Address of the issuance module which will be approved to spend component tokens.
     */
    function approveIndexToken(IIndexToken _indexToken, address _issuanceModule) external {
        address[] memory components = _indexToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            approveToken(IERC20(components[i]), _issuanceModule);
        }
    }

    /**
    * Issues an exact amount of IndexTokens for given amount of input ERC20 tokens.
    * The excess amount of tokens is returned in an equivalent amount of ether.
    *
    * @param _indexToken              Address of the IndexToken to be issued
    * @param _inputToken            Address of the input token
    * @param _amountIndexToken        Amount of IndexTokens to issue
    * @param _maxAmountInputToken   Maximum amount of input tokens to be used to issue IndexTokens.
    * @param _componentQuotes       The encoded 0x transactions to execute 
    *
    * @return totalInputTokenSold   Amount of input token spent for issuance
    */
    function issueExactSetFromToken(
        IIndexToken _indexToken,
        IERC20 _inputToken,
        uint256 _amountIndexToken,
        uint256 _maxAmountInputToken,
        bytes[] memory _componentQuotes,
        address _issuanceModule,
        bool _isDebtIssuance
    )
        isValidModule(_issuanceModule)
        external
        nonReentrant
        returns (uint256)
    {

        _inputToken.safeTransferFrom(msg.sender, address(this), _maxAmountInputToken);
        _safeApprove(_inputToken, swapTarget, _maxAmountInputToken);

        uint256 totalInputTokenSold = _buyComponentsForInputToken(_indexToken, _amountIndexToken,  _componentQuotes, _inputToken, _issuanceModule, _isDebtIssuance);
        require(totalInputTokenSold <= _maxAmountInputToken, "ExchangeIssuance: OVERSPENT TOKEN");

        IBasicIssuanceModule(_issuanceModule).issue(_indexToken, _amountIndexToken, msg.sender);

        _returnExcessInputToken(_inputToken, _maxAmountInputToken, totalInputTokenSold);

        emit ExchangeIssue(msg.sender, _indexToken, _inputToken, _maxAmountInputToken, _amountIndexToken);
        return totalInputTokenSold;
    }


    /**
    * Issues an exact amount of IndexTokens for given amount of ETH.
    * The excess amount of tokens is returned in an equivalent amount of ether.
    *
    * @param _indexToken              Address of the IndexToken to be issued
    * @param _amountIndexToken        Amount of IndexTokens to issue
    * @param _componentQuotes       The encoded 0x transactions to execute
    *
    * @return amountEthReturn       Amount of ether returned to the caller
    */
    function issueExactSetFromETH(
        IIndexToken _indexToken,
        uint256 _amountIndexToken,
        bytes[] memory _componentQuotes,
        address _issuanceModule,
        bool _isDebtIssuance
    )
        isValidModule(_issuanceModule)
        external
        nonReentrant
        payable
        returns (uint256)
    {
        require(msg.value > 0, "ExchangeIssuance: NO ETH SENT");

        IWETH(WETH).deposit{value: msg.value}();
        _safeApprove(IERC20(WETH), swapTarget, msg.value);

        uint256 totalEthSold = _buyComponentsForInputToken(_indexToken, _amountIndexToken, _componentQuotes, IERC20(WETH), _issuanceModule, _isDebtIssuance);

        require(totalEthSold <= msg.value, "ExchangeIssuance: OVERSPENT ETH");
        IBasicIssuanceModule(_issuanceModule).issue(_indexToken, _amountIndexToken, msg.sender);

        uint256 amountEthReturn = msg.value.sub(totalEthSold);
        if (amountEthReturn > 0) {
            IWETH(WETH).withdraw(amountEthReturn);
            payable(msg.sender).sendValue(amountEthReturn);
        }

        emit ExchangeIssue(msg.sender, _indexToken, IERC20(ETH_ADDRESS), totalEthSold, _amountIndexToken);
        return amountEthReturn; 
    }

    /**
     * Redeems an exact amount of IndexTokens for an ERC20 token.
     * The IndexToken must be approved by the sender to this contract.
     *
     * @param _indexToken             Address of the IndexToken being redeemed
     * @param _outputToken          Address of output token
     * @param _amountIndexToken       Amount IndexTokens to redeem
     * @param _minOutputReceive     Minimum amount of output token to receive
     * @param _componentQuotes      The encoded 0x transactions execute (components -> WETH).
     * @param _issuanceModule       Address of issuance Module to use 
     * @param _isDebtIssuance       Flag indicating wether given issuance module is a debt issuance module
     *
     * @return outputAmount         Amount of output tokens sent to the caller
     */
    function redeemExactSetForToken(
        IIndexToken _indexToken,
        IERC20 _outputToken,
        uint256 _amountIndexToken,
        uint256 _minOutputReceive,
        bytes[] memory _componentQuotes,
        address _issuanceModule,
        bool _isDebtIssuance
    )
        isValidModule(_issuanceModule)
        external
        nonReentrant
        returns (uint256)
    {

        uint256 outputAmount;
        _redeemExactSet(_indexToken, _amountIndexToken, _issuanceModule);

        outputAmount = _sellComponentsForOutputToken(_indexToken, _amountIndexToken, _componentQuotes, _outputToken, _issuanceModule, _isDebtIssuance);
        require(outputAmount >= _minOutputReceive, "ExchangeIssuance: INSUFFICIENT OUTPUT AMOUNT");

        // Transfer sender output token
        _outputToken.safeTransfer(msg.sender, outputAmount);
        // Emit event
        emit ExchangeRedeem(msg.sender, _indexToken, _outputToken, _amountIndexToken, outputAmount);
        // Return output amount
        return outputAmount;
    }

    /**
     * Redeems an exact amount of IndexTokens for ETH.
     * The IndexToken must be approved by the sender to this contract.
     *
     * @param _indexToken             Address of the IndexToken being redeemed
     * @param _amountIndexToken       Amount IndexTokens to redeem
     * @param _minEthReceive        Minimum amount of Eth to receive
     * @param _componentQuotes      The encoded 0x transactions execute
     * @param _issuanceModule       Address of issuance Module to use 
     * @param _isDebtIssuance       Flag indicating wether given issuance module is a debt issuance module
     *
     * @return outputAmount         Amount of output tokens sent to the caller
     */
    function redeemExactSetForETH(
        IIndexToken _indexToken,
        uint256 _amountIndexToken,
        uint256 _minEthReceive,
        bytes[] memory _componentQuotes,
        address _issuanceModule,
        bool _isDebtIssuance
    )
        isValidModule(_issuanceModule)
        external
        nonReentrant
        returns (uint256)
    {
        _redeemExactSet(_indexToken, _amountIndexToken, _issuanceModule);
        uint ethAmount = _sellComponentsForOutputToken(_indexToken, _amountIndexToken, _componentQuotes, IERC20(WETH), _issuanceModule, _isDebtIssuance);
        require(ethAmount >= _minEthReceive, "ExchangeIssuance: INSUFFICIENT WETH RECEIVED");

        IWETH(WETH).withdraw(ethAmount);
        (payable(msg.sender)).sendValue(ethAmount);

        emit ExchangeRedeem(msg.sender, _indexToken, IERC20(ETH_ADDRESS), _amountIndexToken, ethAmount);
        return ethAmount;
         
    }
    

    /**
     * Sets a max approval limit for an ERC20 token, provided the current allowance
     * is less than the required allownce.
     *
     * @param _token    Token to approve
     * @param _spender  Spender address to approve
     */
    function _safeApprove(IERC20 _token, address _spender, uint256 _requiredAllowance) internal {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            _token.safeIncreaseAllowance(_spender, type(uint256).max - allowance);
        }
    }

    /**
     * Issues an exact amount of IndexTokens using WETH.
     * Acquires IndexToken components by executing the 0x swaps whose callata is passed in _quotes.
     * Uses the acquired components to issue the IndexTokens.
     *
     * @param _indexToken             Address of the IndexToken being issued
     * @param _amountIndexToken       Amount of IndexTokens to be issued
     * @param _quotes               The encoded 0x transaction calldata to execute against the 0x ExchangeProxy
     * @param _inputToken           Token to use to pay for issuance. Must be the sellToken of the 0x trades.
     * @param _issuanceModule       Issuance module to use for set token issuance.
     *
     * @return totalInputTokenSold  Total amount of input token spent on this issuance
     */
    function _buyComponentsForInputToken(
        IIndexToken _indexToken,
        uint256 _amountIndexToken,
        bytes[] memory _quotes,
        IERC20 _inputToken,
        address _issuanceModule,
        bool _isDebtIssuance
    ) 
    internal
    returns (uint256 totalInputTokenSold)
    {
        uint256 componentAmountBought;

        (address[] memory components, uint256[] memory componentUnits) = getRequiredIssuanceComponents(_issuanceModule, _isDebtIssuance, _indexToken, _amountIndexToken);

        uint256 inputTokenBalanceBefore = _inputToken.balanceOf(address(this));
        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            uint256 units = componentUnits[i];

            // If the component is equal to the input token we don't have to trade
            if(component == address(_inputToken)) {
                totalInputTokenSold = totalInputTokenSold.add(units);
                componentAmountBought = units;
            }
            else {
                uint256 componentBalanceBefore = IERC20(component).balanceOf(address(this));
                _fillQuote(_quotes[i]);
                uint256 componentBalanceAfter = IERC20(component).balanceOf(address(this));
                componentAmountBought = componentBalanceAfter.sub(componentBalanceBefore);
                require(componentAmountBought >= units, "ExchangeIssuance: UNDERBOUGHT COMPONENT");
            }
        }
        uint256 inputTokenBalanceAfter = _inputToken.balanceOf(address(this));
        totalInputTokenSold = totalInputTokenSold.add(inputTokenBalanceBefore.sub(inputTokenBalanceAfter));
    }

    /**
     * Redeems a given list of IndexToken components for given token.
     *
     * @param _indexToken             The set token being swapped.
     * @param _amountIndexToken       The amount of set token being swapped.
     * @param _swaps                An array containing ZeroExSwap swaps.
     * @param _outputToken          The token for which to sell the index components must be the same as the buyToken that was specified when generating the swaps
     * @param _issuanceModule    Address of issuance Module to use 
     * @param _isDebtIssuance    Flag indicating wether given issuance module is a debt issuance module
     *
     * @return totalOutputTokenBought  Total amount of output token received after liquidating all IndexToken components
     */
    function _sellComponentsForOutputToken(IIndexToken _indexToken, uint256 _amountIndexToken, bytes[] memory _swaps, IERC20 _outputToken, address _issuanceModule, bool _isDebtIssuance)
        internal
        returns (uint256 totalOutputTokenBought)
    {
        (address[] memory components, uint256[] memory componentUnits) = getRequiredRedemptionComponents(_issuanceModule, _isDebtIssuance, _indexToken, _amountIndexToken);
        uint256 outputTokenBalanceBefore = _outputToken.balanceOf(address(this));
        for (uint256 i = 0; i < _swaps.length; i++) {
            uint256 maxAmountSell = componentUnits[i];

            uint256 componentAmountSold;

            // If the component is equal to the output token we don't have to trade
            if(components[i] == address(_outputToken)) {
                totalOutputTokenBought = totalOutputTokenBought.add(maxAmountSell);
                componentAmountSold = maxAmountSell;
            }
            else {
                _safeApprove(IERC20(components[i]), address(swapTarget), maxAmountSell);
                uint256 componentBalanceBefore = IERC20(components[i]).balanceOf(address(this));
                _fillQuote(_swaps[i]);
                uint256 componentBalanceAfter = IERC20(components[i]).balanceOf(address(this));
                componentAmountSold = componentBalanceBefore.sub(componentBalanceAfter);
                require(maxAmountSell >= componentAmountSold, "ExchangeIssuance: OVERSOLD COMPONENT");
            }

        }
        uint256 outputTokenBalanceAfter = _outputToken.balanceOf(address(this));
        totalOutputTokenBought = totalOutputTokenBought.add(outputTokenBalanceAfter.sub(outputTokenBalanceBefore));
    }

    /**
     * Execute a 0x Swap quote
     *
     * @param _quote          Swap quote as returned by 0x API
     *
     */
    function _fillQuote(
        bytes memory _quote
    )
        internal
        
    {

        (bool success, bytes memory returndata) = swapTarget.call(_quote);

        // Forwarding errors including new custom errors
        // Taken from: https://ethereum.stackexchange.com/a/111187/73805
        if (!success) {
            if (returndata.length == 0) revert();
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }

    }

    /**
     * Transfers given amount of set token from the sender and redeems it for underlying components.
     * Obtained component tokens are sent to this contract. 
     *
     * @param _indexToken     Address of the IndexToken to be redeemed
     * @param _amount       Amount of IndexToken to be redeemed
     */
    function _redeemExactSet(IIndexToken _indexToken, uint256 _amount, address _issuanceModule) internal returns (uint256) {
        _indexToken.safeTransferFrom(msg.sender, address(this), _amount);
        IBasicIssuanceModule(_issuanceModule).redeem(_indexToken, _amount, address(this));
    }

    /**
     * Returns excess input token
     *
     * @param _inputToken         Address of the input token to return
     * @param _receivedAmount     Amount received by the caller
     * @param _spentAmount        Amount spent for issuance
     */
    function _returnExcessInputToken(IERC20 _inputToken, uint256 _receivedAmount, uint256 _spentAmount) internal {
        uint256 amountTokenReturn = _receivedAmount.sub(_spentAmount);
        if (amountTokenReturn > 0) {
            _inputToken.safeTransfer(msg.sender,  amountTokenReturn);
        }
    }

    /**
     * Returns component positions required for issuance 
     *
     * @param _issuanceModule    Address of issuance Module to use 
     * @param _isDebtIssuance    Flag indicating wether given issuance module is a debt issuance module
     * @param _indexToken          Set token to issue
     * @param _amountIndexToken    Amount of set token to issue
     */
    function getRequiredIssuanceComponents(address _issuanceModule, bool _isDebtIssuance, IIndexToken _indexToken, uint256 _amountIndexToken) public view returns(address[] memory components, uint256[] memory positions) {
        if(_isDebtIssuance) { 
            (components, positions, ) = IDebtIssuanceModule(_issuanceModule).getRequiredComponentIssuanceUnits(_indexToken, _amountIndexToken);
        }
        else {
            (components, positions) = IBasicIssuanceModule(_issuanceModule).getRequiredComponentUnitsForIssue(_indexToken, _amountIndexToken);
        }

    }

    /**
     * Returns component positions required for Redemption 
     *
     * @param _issuanceModule    Address of issuance Module to use 
     * @param _isDebtIssuance    Flag indicating wether given issuance module is a debt issuance module
     * @param _indexToken          Set token to issue
     * @param _amountIndexToken    Amount of set token to issue
     */
    function getRequiredRedemptionComponents(address _issuanceModule, bool _isDebtIssuance, IIndexToken _indexToken, uint256 _amountIndexToken) public view returns(address[] memory components, uint256[] memory positions) {
        if(_isDebtIssuance) { 
            (components, positions, ) = IDebtIssuanceModule(_issuanceModule).getRequiredComponentRedemptionUnits(_indexToken, _amountIndexToken);
        }
        else {
            components = _indexToken.getComponents();
            positions = new uint256[](components.length);
            for(uint256 i = 0; i < components.length; i++) {
                uint256 unit = uint256(_indexToken.getDefaultPositionRealUnit(components[i]));
                positions[i] = unit.preciseMul(_amountIndexToken);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity 0.6.10;

import {IIndexToken} from "./IIndexToken.sol";

/**
 * @title IDebtIssuanceModule

 *
 * Interface for interacting with Debt Issuance module interface.
 */
interface IDebtIssuanceModule {
    /**
     * Called by another module to register itself on debt issuance module. Any logic can be included
     * in case checks need to be made or state needs to be updated.
     */
    function registerToIssuanceModule(IIndexToken _indexToken) external;

    /**
     * Called by another module to unregister itself on debt issuance module. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function unregisterFromIssuanceModule(IIndexToken _indexToken) external;

    function getRequiredComponentIssuanceUnits(
        IIndexToken _indexToken,
        uint256 _quantity
    ) external view returns (address[] memory, uint256[] memory, uint256[] memory);

    function getRequiredComponentRedemptionUnits(
        IIndexToken _indexToken,
        uint256 _quantity
    ) external view returns (address[] memory, uint256[] memory, uint256[] memory);
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

interface IController {
    function addIndex(address _indexToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isIndex(address _indexToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH
 * @author Set Protocol
 *
 * Interface for Wrapped Ether. This interface allows for interaction for wrapped ether's deposit and withdrawal
 * functionality.
 */
interface IWETH is IERC20{
    function deposit()
        external
        payable;

    function withdraw(
        uint256 wad
    )
        external;
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";
import { IController } from "../interfaces/IController.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IOracleAdapter } from "../interfaces/IOracleAdapter.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";


/**
 * @title PriceOracle
 *
 * Contract that returns the price for any given asset pair. Price is retrieved either directly from an oracle,
 * calculated using common asset pairs, or uses external data to calculate price.
 * Note: Prices are returned in preciseUnits (i.e. 18 decimals of precision)
 */
contract PriceOracle is Ownable {
    using PreciseUnitMath for uint256;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event PairAdded(address indexed _assetOne, address indexed _assetTwo, address _oracle);
    event PairRemoved(address indexed _assetOne, address indexed _assetTwo, address _oracle);
    event PairEdited(address indexed _assetOne, address indexed _assetTwo, address _newOracle);
    event AdapterAdded(address _adapter);
    event AdapterRemoved(address _adapter);
    event MasterQuoteAssetEdited(address _newMasterQuote);

    /* ============ State Variables ============ */

    // Address of the Controller contract
    IController public controller;

    // Mapping between assetA/assetB and its associated Price Oracle
    // Asset 1 -> Asset 2 -> IOracle Interface
    mapping(address => mapping(address => IOracle)) public oracles;

    // Token address of the bridge asset that prices are derived from if the specified pair price is missing
    address public masterQuoteAsset;

    // List of IOracleAdapters used to return prices of third party protocols (e.g. Uniswap, Compound, Balancer)
    address[] public adapters;

    /* ============ Constructor ============ */

    /**
     * Index state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     * @param _masterQuoteAsset       Address of asset that can be used to link unrelated asset pairs
     * @param _adapters               List of adapters used to price assets created by other protocols
     * @param _assetOnes              List of first asset in pair, index i maps to same index in assetTwos and oracles
     * @param _assetTwos              List of second asset in pair, index i maps to same index in assetOnes and oracles
     * @param _oracles                List of oracles, index i maps to same index in assetOnes and assetTwos
     */
    constructor(
        IController _controller,
        address _masterQuoteAsset,
        address[] memory _adapters,
        address[] memory _assetOnes,
        address[] memory _assetTwos,
        IOracle[] memory _oracles
    )
        public
    {
        controller = _controller;
        masterQuoteAsset = _masterQuoteAsset;
        adapters = _adapters;
        require(
            _assetOnes.length == _assetTwos.length && _assetTwos.length == _oracles.length,
            "Array lengths do not match."
        );

        for (uint256 i = 0; i < _assetOnes.length; i++) {
            oracles[_assetOnes[i]][_assetTwos[i]] = _oracles[i];
        }
    }

    /* ============ External Functions ============ */

    /**
     * SYSTEM-ONLY PRIVELEGE: Find price of passed asset pair, if possible. The steps it takes are:
     *  1) Check to see if a direct or inverse oracle of the pair exists,
     *  2) If not, use masterQuoteAsset to link pairs together (i.e. BTC/ETH and ETH/USDC
     *     could be used to calculate BTC/USDC).
     *  3) If not, check oracle adapters in case one or more of the assets needs external protocol data
     *     to price.
     *  4) If all steps fail, revert.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return                  Price of asset pair to 18 decimals of precision
     */
    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256) {
        require(
            controller.isSystemContract(msg.sender),
            "PriceOracle.getPrice: Caller must be system contract."
        );

        bool priceFound;
        uint256 price;

        (priceFound, price) = _getDirectOrInversePrice(_assetOne, _assetTwo);

        if (!priceFound) {
            (priceFound, price) = _getPriceFromMasterQuote(_assetOne, _assetTwo);
        }

        if (!priceFound) {
            (priceFound, price) = _getPriceFromAdapters(_assetOne, _assetTwo);
        }

        require(priceFound, "PriceOracle.getPrice: Price not found.");

        return price;
    }

    /**
     * GOVERNANCE FUNCTION: Add new asset pair oracle.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @param _oracle           Address of asset pair's oracle
     */
    function addPair(address _assetOne, address _assetTwo, IOracle _oracle) external onlyOwner {
        require(
            address(oracles[_assetOne][_assetTwo]) == address(0),
            "PriceOracle.addPair: Pair already exists."
        );
        oracles[_assetOne][_assetTwo] = _oracle;

        emit PairAdded(_assetOne, _assetTwo, address(_oracle));
    }

    /**
     * GOVERNANCE FUNCTION: Edit an existing asset pair's oracle.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @param _oracle           Address of asset pair's new oracle
     */
    function editPair(address _assetOne, address _assetTwo, IOracle _oracle) external onlyOwner {
        require(
            address(oracles[_assetOne][_assetTwo]) != address(0),
            "PriceOracle.editPair: Pair doesn't exist."
        );
        oracles[_assetOne][_assetTwo] = _oracle;

        emit PairEdited(_assetOne, _assetTwo, address(_oracle));
    }

    /**
     * GOVERNANCE FUNCTION: Remove asset pair's oracle.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     */
    function removePair(address _assetOne, address _assetTwo) external onlyOwner {
        require(
            address(oracles[_assetOne][_assetTwo]) != address(0),
            "PriceOracle.removePair: Pair doesn't exist."
        );
        IOracle oldOracle = oracles[_assetOne][_assetTwo];
        delete oracles[_assetOne][_assetTwo];

        emit PairRemoved(_assetOne, _assetTwo, address(oldOracle));
    }

    /**
     * GOVERNANCE FUNCTION: Add new oracle adapter.
     *
     * @param _adapter         Address of new adapter
     */
    function addAdapter(address _adapter) external onlyOwner {
        require(
            !adapters.contains(_adapter),
            "PriceOracle.addAdapter: Adapter already exists."
        );
        adapters.push(_adapter);

        emit AdapterAdded(_adapter);
    }

    /**
     * GOVERNANCE FUNCTION: Remove oracle adapter.
     *
     * @param _adapter         Address of adapter to remove
     */
    function removeAdapter(address _adapter) external onlyOwner {
        require(
            adapters.contains(_adapter),
            "PriceOracle.removeAdapter: Adapter does not exist."
        );
        adapters = adapters.remove(_adapter);

        emit AdapterRemoved(_adapter);
    }

    /**
     * GOVERNANCE FUNCTION: Change the master quote asset.
     *
     * @param _newMasterQuoteAsset         New address of master quote asset
     */
    function editMasterQuoteAsset(address _newMasterQuoteAsset) external onlyOwner {
        masterQuoteAsset = _newMasterQuoteAsset;

        emit MasterQuoteAssetEdited(_newMasterQuoteAsset);
    }

    /* ============ External View Functions ============ */

    /**
     * Returns an array of adapters
     */
    function getAdapters() external view returns (address[] memory) {
        return adapters;
    }

    /* ============ Internal Functions ============ */

    /**
     * Check if direct or inverse oracle exists. If so return that price along with boolean indicating
     * it exists. Otherwise return boolean indicating oracle doesn't exist.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return bool             Boolean indicating if oracle exists
     * @return uint256          Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getDirectOrInversePrice(
        address _assetOne,
        address _assetTwo
    )
        internal
        view
        returns (bool, uint256)
    {
        IOracle directOracle = oracles[_assetOne][_assetTwo];
        bool hasDirectOracle = address(directOracle) != address(0);

        // Check asset1 -> asset 2. If exists, then return value
        if (hasDirectOracle) {
            return (true, directOracle.read());
        }

        IOracle inverseOracle = oracles[_assetTwo][_assetOne];
        bool hasInverseOracle = address(inverseOracle) != address(0);

        // If not, check asset 2 -> asset 1. If exists, then return 1 / asset1 -> asset2
        if (hasInverseOracle) {
            return (true, _calculateInversePrice(inverseOracle));
        }

        return (false, 0);
    }

    /**
     * Try to calculate asset pair price by getting each asset in the pair's price relative to master
     * quote asset. Both prices must exist otherwise function returns false and no price.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return bool             Boolean indicating if oracle exists
     * @return uint256          Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getPriceFromMasterQuote(
        address _assetOne,
        address _assetTwo
    )
        internal
        view
        returns (bool, uint256)
    {
        (
            bool priceFoundOne,
            uint256 assetOnePrice
        ) = _getDirectOrInversePrice(_assetOne, masterQuoteAsset);

        (
            bool priceFoundTwo,
            uint256 assetTwoPrice
        ) = _getDirectOrInversePrice(_assetTwo, masterQuoteAsset);

        if (priceFoundOne && priceFoundTwo) {
            return (true, assetOnePrice.preciseDiv(assetTwoPrice));
        }

        return (false, 0);
    }

    /**
     * Scan adapters to see if one or more of the assets needs external protocol data to be priced. If
     * does not exist return false and no price.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return bool             Boolean indicating if oracle exists
     * @return uint256          Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getPriceFromAdapters(
        address _assetOne,
        address _assetTwo
    )
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < adapters.length; i++) {
            (
                bool priceFound,
                uint256 price
            ) = IOracleAdapter(adapters[i]).getPrice(_assetOne, _assetTwo);

            if (priceFound) {
                return (priceFound, price);
            }
        }

        return (false, 0);
    }

    /**
     * Calculate inverse price of passed oracle. The inverse price is 1 (or 1e18) / inverse price
     *
     * @param _inverseOracle        Address of oracle to invert
     * @return uint256              Inverted price of asset pair to 18 decimal precision
     */
    function _calculateInversePrice(IOracle _inverseOracle) internal view returns(uint256) {
        uint256 inverseValue = _inverseOracle.read();

        return PreciseUnitMath.preciseUnit().preciseDiv(inverseValue);
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 *
 * Utility functions to handle Address Arrays
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;


/**
 * @title IOracle
 *
 * Interface for operating with any external Oracle that returns uint256 or
 * an adapting contract that converts oracle output to uint256
 */
interface IOracle {
    /**
     * @return  Current price of asset represented in uint256, typically a preciseUnit where 10^18 = 1.
     */
    function read() external view returns (uint256);
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;


/**
 * @title IOracleAdapter
 *
 * Interface for calling an oracle adapter.
 */
interface IOracleAdapter {

    /**
     * Function for retrieving a price that requires sourcing data from outside protocols to calculate.
     *
     * @param  _assetOne    First asset in pair
     * @param  _assetTwo    Second asset in pair
     * @return                  Boolean indicating if oracle exists
     * @return              Current price of asset represented in uint256
     */
    function getPrice(address _assetOne, address _assetTwo) external view returns (bool, uint256);
}

// SPDX-License-Identifier: Apache License, Version 2.0


pragma solidity ^0.6.10;
pragma experimental "ABIEncoderV2";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IController } from "../../interfaces/IController.sol";
import { IExchangeAdapter } from "../../interfaces/IExchangeAdapter.sol";
import { IIntegrationRegistry } from "../../interfaces/IIntegrationRegistry.sol";
import { Invoke } from "../lib/Invoke.sol";
import { IIndexToken } from "../../interfaces/IIndexToken.sol";
import { ModuleBase } from "../lib/ModuleBase.sol";
import { Position } from "../lib/Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";

/**
 * @title TradeModule
 
 *
 * Module that enables IndexTokens to perform atomic trades using Decentralized Exchanges
 * such as 1inch or Kyber. Integrations mappings are stored on the IntegrationRegistry contract.
 */
contract TradeModule is ModuleBase, ReentrancyGuard {
    using SafeCast for int256;
    using SafeMath for uint256;

    using Invoke for IIndexToken;
    using Position for IIndexToken;
    using PreciseUnitMath for uint256;

    /* ============ Struct ============ */

    struct TradeInfo {
        IIndexToken setToken;                             // Instance of IndexToken
        IExchangeAdapter exchangeAdapter;               // Instance of exchange adapter contract
        address sendToken;                              // Address of token being sold
        address receiveToken;                           // Address of token being bought
        uint256 setTotalSupply;                         // Total supply of IndexToken in Precise Units (10^18)
        uint256 totalSendQuantity;                      // Total quantity of sold token (position unit x total supply)
        uint256 totalMinReceiveQuantity;                // Total minimum quantity of token to receive back
        uint256 preTradeSendTokenBalance;               // Total initial balance of token being sold
        uint256 preTradeReceiveTokenBalance;            // Total initial balance of token being bought
    }

    /* ============ Events ============ */

    event ComponentExchanged(
        IIndexToken indexed _indexToken,
        address indexed _sendToken,
        address indexed _receiveToken,
        IExchangeAdapter _exchangeAdapter,
        uint256 _totalSendAmount,
        uint256 _totalReceiveAmount,
        uint256 _protocolFee
    );

    /* ============ Constants ============ */

    // 0 index stores the fee % charged in the trade function
    uint256 constant internal TRADE_MODULE_PROTOCOL_FEE_INDEX = 0;

    /* ============ Constructor ============ */

    constructor(IController _controller) public ModuleBase(_controller) {}

    /* ============ External Functions ============ */

    /**
     * Initializes this module to the IndexToken. Only callable by the IndexToken's manager.
     *
     * @param _indexToken                 Instance of the IndexToken to initialize
     */
    function initialize(
        IIndexToken _indexToken
    )
        external
        onlyValidAndPendingIndex(_indexToken)
        onlyIndexManager(_indexToken, msg.sender)
    {
        _indexToken.initializeModule();
    }

    /**
     * Executes a trade on a supported DEX. Only callable by the IndexToken's manager.
     * @dev Although the IndexToken units are passed in for the send and receive quantities, the total quantity
     * sent and received is the quantity of IndexToken units multiplied by the IndexToken totalSupply.
     *
     * @param _indexToken             Instance of the IndexToken to trade
     * @param _exchangeName         Human readable name of the exchange in the integrations registry
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _sendQuantity         Units of token in IndexToken sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _minReceiveQuantity   Min units of token in IndexToken to be received from the exchange
     * @param _data                 Arbitrary bytes to be used to construct trade call data
     */
    function trade(
        IIndexToken _indexToken,
        string memory _exchangeName,
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _minReceiveQuantity,
        bytes memory _data
    )
        external
        nonReentrant
        onlyManagerAndValidIndex(_indexToken)
    {
        TradeInfo memory tradeInfo = _createTradeInfo(
            _indexToken,
            _exchangeName,
            _sendToken,
            _receiveToken,
            _sendQuantity,
            _minReceiveQuantity
        );

        _validatePreTradeData(tradeInfo, _sendQuantity);

        _executeTrade(tradeInfo, _data);

        uint256 exchangedQuantity = _validatePostTrade(tradeInfo);

        uint256 protocolFee = _accrueProtocolFee(tradeInfo, exchangedQuantity);

        (
            uint256 netSendAmount,
            uint256 netReceiveAmount
        ) = _updateIndexTokenPositions(tradeInfo);

        emit ComponentExchanged(
            _indexToken,
            _sendToken,
            _receiveToken,
            tradeInfo.exchangeAdapter,
            netSendAmount,
            netReceiveAmount,
            protocolFee
        );
    }

    /**
     * Removes this module from the IndexToken, via call by the IndexToken. Left with empty logic
     * here because there are no check needed to verify removal.
     */
    function removeModule() external override {}

    /* ============ Internal Functions ============ */

    /**
     * Create and return TradeInfo struct
     *
     * @param _indexToken             Instance of the IndexToken to trade
     * @param _exchangeName         Human readable name of the exchange in the integrations registry
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _sendQuantity         Units of token in IndexToken sent to the exchange
     * @param _minReceiveQuantity   Min units of token in IndexToken to be received from the exchange
     *
     * return TradeInfo             Struct containing data for trade
     */
    function _createTradeInfo(
        IIndexToken _indexToken,
        string memory _exchangeName,
        address _sendToken,
        address _receiveToken,
        uint256 _sendQuantity,
        uint256 _minReceiveQuantity
    )
        internal
        view
        returns (TradeInfo memory)
    {
        TradeInfo memory tradeInfo;

        tradeInfo.setToken = _indexToken;

        tradeInfo.exchangeAdapter = IExchangeAdapter(getAndValidateAdapter(_exchangeName));

        tradeInfo.sendToken = _sendToken;
        tradeInfo.receiveToken = _receiveToken;

        tradeInfo.setTotalSupply = _indexToken.totalSupply();

        tradeInfo.totalSendQuantity = Position.getDefaultTotalNotional(tradeInfo.setTotalSupply, _sendQuantity);

        tradeInfo.totalMinReceiveQuantity = Position.getDefaultTotalNotional(tradeInfo.setTotalSupply, _minReceiveQuantity);

        tradeInfo.preTradeSendTokenBalance = IERC20(_sendToken).balanceOf(address(_indexToken));
        tradeInfo.preTradeReceiveTokenBalance = IERC20(_receiveToken).balanceOf(address(_indexToken));

        return tradeInfo;
    }

    /**
     * Validate pre trade data. Check exchange is valid, token quantity is valid.
     *
     * @param _tradeInfo            Struct containing trade information used in internal functions
     * @param _sendQuantity         Units of token in IndexToken sent to the exchange
     */
    function _validatePreTradeData(TradeInfo memory _tradeInfo, uint256 _sendQuantity) internal view {
        require(_tradeInfo.totalSendQuantity > 0, "Token to sell must be nonzero");

        require(
            _tradeInfo.setToken.hasSufficientDefaultUnits(_tradeInfo.sendToken, _sendQuantity),
            "Unit cant be greater than existing"
        );
    }

    /**
     * Invoke approve for send token, get method data and invoke trade in the context of the IndexToken.
     *
     * @param _tradeInfo            Struct containing trade information used in internal functions
     * @param _data                 Arbitrary bytes to be used to construct trade call data
     */
    function _executeTrade(
        TradeInfo memory _tradeInfo,
        bytes memory _data
    )
        internal
    {
        // Get spender address from exchange adapter and invoke approve for exact amount on IndexToken
        _tradeInfo.setToken.invokeApprove(
            _tradeInfo.sendToken,
            _tradeInfo.exchangeAdapter.getSpender(),
            _tradeInfo.totalSendQuantity
        );

        (
            address targetExchange,
            uint256 callValue,
            bytes memory methodData
        ) = _tradeInfo.exchangeAdapter.getTradeCalldata(
            _tradeInfo.sendToken,
            _tradeInfo.receiveToken,
            address(_tradeInfo.setToken),
            _tradeInfo.totalSendQuantity,
            _tradeInfo.totalMinReceiveQuantity,
            _data
        );

        _tradeInfo.setToken.invoke(targetExchange, callValue, methodData);
    }

    /**
     * Validate post trade data.
     *
     * @param _tradeInfo                Struct containing trade information used in internal functions
     * @return uint256                  Total quantity of receive token that was exchanged
     */
    function _validatePostTrade(TradeInfo memory _tradeInfo) internal view returns (uint256) {
        uint256 exchangedQuantity = IERC20(_tradeInfo.receiveToken)
            .balanceOf(address(_tradeInfo.setToken))
            .sub(_tradeInfo.preTradeReceiveTokenBalance);

        require(
            exchangedQuantity >= _tradeInfo.totalMinReceiveQuantity,
            "Slippage greater than allowed"
        );

        return exchangedQuantity;
    }

    /**
     * Retrieve fee from controller and calculate total protocol fee and send from IndexToken to protocol recipient
     *
     * @param _tradeInfo                Struct containing trade information used in internal functions
     * @return uint256                  Amount of receive token taken as protocol fee
     */
    function _accrueProtocolFee(TradeInfo memory _tradeInfo, uint256 _exchangedQuantity) internal returns (uint256) {
        uint256 protocolFeeTotal = getModuleFee(TRADE_MODULE_PROTOCOL_FEE_INDEX, _exchangedQuantity);
        
        payProtocolFeeFromIndexToken(_tradeInfo.setToken, _tradeInfo.receiveToken, protocolFeeTotal);
        
        return protocolFeeTotal;
    }

    /**
     * Update IndexToken positions
     *
     * @param _tradeInfo                Struct containing trade information used in internal functions
     * @return uint256                  Amount of sendTokens used in the trade
     * @return uint256                  Amount of receiveTokens received in the trade (net of fees)
     */
    function _updateIndexTokenPositions(TradeInfo memory _tradeInfo) internal returns (uint256, uint256) {
        (uint256 currentSendTokenBalance,,) = _tradeInfo.setToken.calculateAndEditDefaultPosition(
            _tradeInfo.sendToken,
            _tradeInfo.setTotalSupply,
            _tradeInfo.preTradeSendTokenBalance
        );

        (uint256 currentReceiveTokenBalance,,) = _tradeInfo.setToken.calculateAndEditDefaultPosition(
            _tradeInfo.receiveToken,
            _tradeInfo.setTotalSupply,
            _tradeInfo.preTradeReceiveTokenBalance
        );

        return (
            _tradeInfo.preTradeSendTokenBalance.sub(currentSendTokenBalance),
            currentReceiveTokenBalance.sub(_tradeInfo.preTradeReceiveTokenBalance)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

interface IExchangeAdapter {
    function getSpender() external view returns(address);
    function getTradeCalldata(
        address _fromToken,
        address _toToken,
        address _toAddress,
        uint256 _fromQuantity,
        uint256 _minToQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory);
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IIndexToken } from "../../interfaces/IIndexToken.sol";


/**
 * @title Invoke
 *
 * A collection of common utility functions for interacting with the IndexToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the IndexToken to set approvals of the ERC20 token to a spender.
     *
     * @param _indexToken        IndexToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the IndexToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        IIndexToken _indexToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _indexToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the IndexToken to transfer the ERC20 token to a recipient.
     *
     * @param _indexToken        IndexToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        IIndexToken _indexToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _indexToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the IndexToken to transfer the ERC20 token to a recipient.
     * The new IndexToken balance must equal the existing balance less the quantity transferred
     *
     * @param _indexToken        IndexToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        IIndexToken _indexToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the IndexToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_indexToken));

            Invoke.invokeTransfer(_indexToken, _token, _to, _quantity);

            // Get new balance of transferred token for IndexToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_indexToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the IndexToken to unwrap the passed quantity of WETH
     *
     * @param _indexToken        IndexToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(IIndexToken _indexToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _indexToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the IndexToken to wrap the passed quantity of ETH
     *
     * @param _indexToken        IndexToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(IIndexToken _indexToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _indexToken.invoke(_weth, _quantity, callData);
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { ExplicitERC20 } from "./ExplicitERC20.sol";
import { IController } from "../../interfaces/IController.sol";
import { IModule } from "../../interfaces/IModule.sol";
import { IIndexToken } from "../../interfaces/IIndexToken.sol";
import { Invoke } from "./Invoke.sol";
import { Position } from "./Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./ResourceIdentifier.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for IIndexToken;
    using Position for IIndexToken;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidIndex(IIndexToken _indexToken) {
        _validateOnlyManagerAndValidIndex(_indexToken);
        _;
    }

    modifier onlyIndexManager(IIndexToken _indexToken, address _caller) {
        _validateOnlyIndexManager(_indexToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedIndex(IIndexToken _indexToken) {
        _validateOnlyValidAndInitializedIndex(_indexToken);
        _;
    }

    /**
     * Throws if the sender is not a IndexToken's module or module not enabled
     */
    modifier onlyModule(IIndexToken _indexToken) {
        _validateOnlyModule(_indexToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the IndexToken is valid
     */
    modifier onlyValidAndPendingIndex(IIndexToken _indexToken) {
        _validateOnlyValidAndPendingIndex(_indexToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) { 
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) { 
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter"); 
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _indexToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromIndexToken(IIndexToken _indexToken, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _indexToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity); 
        }
    }

    /**
     * Returns true if the module is in process of initialization on the IndexToken
     */
    function isIndexPendingInitialization(IIndexToken _indexToken) internal view returns(bool) {
        return _indexToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the IndexToken's manager
     */
    function isIndexManager(IIndexToken _indexToken, address _toCheck) internal view returns(bool) {
        return _indexToken.manager() == _toCheck;
    }

    /**
     * Returns true if IndexToken must be enabled on the controller 
     * and module is registered on the IndexToken
     */
    function isIndexValidAndInitialized(IIndexToken _indexToken) internal view returns(bool) {
        return controller.isIndex(address(_indexToken)) &&
            _indexToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must IndexToken manager and IndexToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidIndex(IIndexToken _indexToken) internal view {
       require(isIndexManager(_indexToken, msg.sender), "Must be the IndexToken manager");
       require(isIndexValidAndInitialized(_indexToken), "Must be a valid and initialized IndexToken");
    }

    /**
     * Caller must IndexToken manager
     */
    function _validateOnlyIndexManager(IIndexToken _indexToken, address _caller) internal view {
        require(isIndexManager(_indexToken, _caller), "Must be the IndexToken manager");
    }

    /**
     * IndexToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedIndex(IIndexToken _indexToken) internal view {
        require(isIndexValidAndInitialized(_indexToken), "Must be a valid and initialized IndexToken");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(IIndexToken _indexToken) internal view {
        require(
            _indexToken.moduleStates(msg.sender) == IIndexToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * IndexToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingIndex(IIndexToken _indexToken) internal view {
        require(controller.isIndex(address(_indexToken)), "Must be controller-enabled IndexToken");
        require(isIndexPendingInitialization(_indexToken), "Must be pending initialization");
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IIndexToken } from "../../interfaces/IIndexToken.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";


/**
 * @title Position
 *
 * Collection of helper functions for handling and updating IndexToken Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the IndexToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(IIndexToken _indexToken, address _component) internal view returns(bool) {
        return _indexToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the IndexToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(IIndexToken _indexToken, address _component) internal view returns(bool) {
        return _indexToken.getExternalPositionModules(_component).length > 0;
    }
    
    /**
     * Returns whether the IndexToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(IIndexToken _indexToken, address _component, uint256 _unit) internal view returns(bool) {
        return _indexToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }

    /**
     * Returns whether the IndexToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        IIndexToken _indexToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _indexToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();    
    }

    /**
     * If the position does not exist, create a new Position and add to the IndexToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of 
     * components where needed (in light of potential external positions).
     *
     * @param _indexToken           Address of IndexToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(IIndexToken _indexToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_indexToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_indexToken, _component)) {
                _indexToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_indexToken, _component)) {
                _indexToken.removeComponent(_component);
            }
        }

        _indexToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position. 
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _indexToken         IndexToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        IIndexToken _indexToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (_newUnit != 0) {
            if (!_indexToken.isComponent(_component)) {
                _indexToken.addComponent(_component);
                _indexToken.addExternalPositionModule(_component, _module);
            } else if (!_indexToken.isExternalPositionModule(_component, _module)) {
                _indexToken.addExternalPositionModule(_component, _module);
            }
            _indexToken.editExternalPositionUnit(_component, _module, _newUnit);
            _indexToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (_indexToken.getExternalPositionRealUnit(_component, _module) != 0) {
                address[] memory positionModules = _indexToken.getExternalPositionModules(_component);
                if (_indexToken.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == _module, "External positions must be 0 to remove component");
                    _indexToken.removeComponent(_component);
                }
                _indexToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _indexTokenSupply     Supply of IndexToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 _indexTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _indexTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _indexTokenSupply     Supply of IndexToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(uint256 _indexTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_indexTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _indexToken           Address of the IndexToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(IIndexToken _indexToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _indexToken.getDefaultPositionRealUnit(_component); 
        return _indexToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _indexToken                 Address of the IndexToken
     * @param _component                Address of the component
     * @param _setTotalSupply           Current IndexToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        IIndexToken _indexToken,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_indexToken));
        uint256 positionUnit = _indexToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _setTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_indexToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes IndexToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _indexTokenSupply     Supply of IndexToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of IndexToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _indexTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_indexTokenSupply));
        return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_indexTokenSupply);
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
    using SafeMath for uint256;

    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;


/**
 * @title IModule
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a IndexToken to notify that this module was removed from the Set token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IController } from "../../interfaces/IController.sol";
import { IIntegrationRegistry } from "../../interfaces/IIntegrationRegistry.sol";
import { IPriceOracle } from "../../interfaces/IPriceOracle.sol";
import { IIndexValuer } from "../../interfaces/IIndexValuer.sol";

/**
 * @title ResourceIdentifier
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (IIndexValuer) {
        return IIndexValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

/**
 * @title IPriceOracle
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IIndexToken } from "../interfaces/IIndexToken.sol";

interface IIndexValuer {
    function calculateIndexTokenValuation(IIndexToken _indexToken, address _quoteAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IController } from "../../interfaces/IController.sol";
import { IManagerIssuanceHook } from "../../interfaces/IManagerIssuanceHook.sol";
import { Invoke } from "../lib/Invoke.sol";
import { IIndexToken } from "../../interfaces/IIndexToken.sol";
import { ModuleBase } from "../lib/ModuleBase.sol";
import { Position } from "../lib/Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";

/**
 * @title BasicIssuanceModule
 *
 * Module that enables issuance and redemption functionality on a IndexToken. This is a module that is
 * required to bring the totalSupply of a Index above 0.
 */
contract BasicIssuanceModule is ModuleBase, ReentrancyGuard {
    using Invoke for IIndexToken;
    using Position for IIndexToken.Position;
    using Position for IIndexToken;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;

    /* ============ Events ============ */

    event IndexTokenIssued(
        address indexed _indexToken,
        address indexed _issuer,
        address indexed _to,
        address _hookContract,
        uint256 _quantity
    );
    event IndexTokenRedeemed(
        address indexed _indexToken,
        address indexed _redeemer,
        address indexed _to,
        uint256 _quantity
    );

    /* ============ State Variables ============ */

    // Mapping of IndexToken to Issuance hook configurations
    mapping(IIndexToken => IManagerIssuanceHook) public managerIssuanceHook;

    /* ============ Constructor ============ */

    /**
     * Index state controller state variable
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public ModuleBase(_controller) {}

    /* ============ External Functions ============ */

    /**
     * Deposits the IndexToken's position components into the IndexToken and mints the IndexToken of the given quantity
     * to the specified _to address. This function only handles Default Positions (positionState = 0).
     *
     * @param _indexToken             Instance of the IndexToken contract
     * @param _quantity             Quantity of the IndexToken to mint
     * @param _to                   Address to mint IndexToken to
     */
    function issue(
        IIndexToken _indexToken,
        uint256 _quantity,
        address _to
    ) 
        external
        nonReentrant
        onlyValidAndInitializedIndex(_indexToken)
    {
        require(_quantity > 0, "Issue quantity must be > 0");

        address hookContract = _callPreIssueHooks(_indexToken, _quantity, msg.sender, _to);

        (
            address[] memory components,
            uint256[] memory componentQuantities
        ) = getRequiredComponentUnitsForIssue(_indexToken, _quantity);

        // For each position, transfer the required underlying to the IndexToken
        for (uint256 i = 0; i < components.length; i++) {
            // Transfer the component to the IndexToken
            transferFrom(
                IERC20(components[i]),
                msg.sender,
                address(_indexToken),
                componentQuantities[i]
            );
        }

        // Mint the IndexToken
        _indexToken.mint(_to, _quantity);

        emit IndexTokenIssued(address(_indexToken), msg.sender, _to, hookContract, _quantity);
    }

    /**
     * Redeems the IndexToken's positions and sends the components of the given
     * quantity to the caller. This function only handles Default Positions (positionState = 0).
     *
     * @param _indexToken             Instance of the IndexToken contract
     * @param _quantity             Quantity of the IndexToken to redeem
     * @param _to                   Address to send component assets to
     */
    function redeem(
        IIndexToken _indexToken,
        uint256 _quantity,
        address _to
    )
        external
        nonReentrant
        onlyValidAndInitializedIndex(_indexToken)
    {
        require(_quantity > 0, "Redeem quantity must be > 0");

        // Burn the IndexToken - ERC20's internal burn already checks that the user has enough balance
        _indexToken.burn(msg.sender, _quantity);

        // For each position, invoke the IndexToken to transfer the tokens to the user
        address[] memory components = _indexToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            require(!_indexToken.hasExternalPosition(component), "Only default positions are supported");

            uint256 unit = _indexToken.getDefaultPositionRealUnit(component).toUint256();

            // Use preciseMul to round down to ensure overcollateration when small redeem quantities are provided
            uint256 componentQuantity = _quantity.preciseMul(unit);

            // Instruct the IndexToken to transfer the component to the user
            _indexToken.strictInvokeTransfer(
                component,
                _to,
                componentQuantity
            );
        }

        emit IndexTokenRedeemed(address(_indexToken), msg.sender, _to, _quantity);
    }

    /**
     * Initializes this module to the IndexToken with issuance-related hooks. Only callable by the IndexToken's manager.
     * Hook addresses are optional. Address(0) means that no hook will be called
     *
     * @param _indexToken             Instance of the IndexToken to issue
     * @param _preIssueHook         Instance of the Manager Contract with the Pre-Issuance Hook function
     */
    function initialize(
        IIndexToken _indexToken,
        IManagerIssuanceHook _preIssueHook
    )
        external
        onlyIndexManager(_indexToken, msg.sender)
        onlyValidAndPendingIndex(_indexToken)
    {
        managerIssuanceHook[_indexToken] = _preIssueHook;

        _indexToken.initializeModule();
    }

    /**
     * Reverts as this module should not be removable after added. Users should always
     * have a way to redeem their Sets
     */
    function removeModule() external override {
        revert("The BasicIssuanceModule module cannot be removed");
    }

    /* ============ External Getter Functions ============ */

    /**
     * Retrieves the addresses and units required to mint a particular quantity of IndexToken.
     *
     * @param _indexToken             Instance of the IndexToken to issue
     * @param _quantity             Quantity of IndexToken to issue
     * @return address[]            List of component addresses
     * @return uint256[]            List of component units required to issue the quantity of IndexTokens
     */
    function getRequiredComponentUnitsForIssue(
        IIndexToken _indexToken,
        uint256 _quantity
    )
        public
        view
        onlyValidAndInitializedIndex(_indexToken)
        returns (address[] memory, uint256[] memory)
    {
        address[] memory components = _indexToken.getComponents();

        uint256[] memory notionalUnits = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            require(!_indexToken.hasExternalPosition(components[i]), "Only default positions are supported");

            notionalUnits[i] = _indexToken.getDefaultPositionRealUnit(components[i]).toUint256().preciseMulCeil(_quantity);
        }

        return (components, notionalUnits);
    }

    /* ============ Internal Functions ============ */

    /**
     * If a pre-issue hook has been configured, call the external-protocol contract. Pre-issue hook logic
     * can contain arbitrary logic including validations, external function calls, etc.
     */
    function _callPreIssueHooks(
        IIndexToken _indexToken,
        uint256 _quantity,
        address _caller,
        address _to
    )
        internal
        returns(address)
    {
        IManagerIssuanceHook preIssueHook = managerIssuanceHook[_indexToken];
        if (address(preIssueHook) != address(0)) {
            preIssueHook.invokePreIssueHook(_indexToken, _quantity, _caller, _to);
            return address(preIssueHook);
        }

        return address(0);
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IIndexToken } from "./IIndexToken.sol";

interface IManagerIssuanceHook {
    function invokePreIssueHook(IIndexToken _indexToken, uint256 _issueQuantity, address _sender, address _to) external;
    function invokePreRedeemHook(IIndexToken _indexToken, uint256 _redeemQuantity, address _sender, address _to) external;
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IController } from "../interfaces/IController.sol";
import { IIndexToken } from "../interfaces/IIndexToken.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { Position } from "./lib/Position.sol";
import { ResourceIdentifier } from "./lib/ResourceIdentifier.sol";


/**
 * @title IndexValuer
 *
 * Contract that returns the valuation of IndexTokens using price oracle data used in contracts
 * that are external to the system.
 *
 * Note: Prices are returned in preciseUnits (i.e. 18 decimals of precision)
 */
contract IndexValuer {
    using PreciseUnitMath for int256;
    using PreciseUnitMath for uint256;
    using Position for IIndexToken;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;
    
    /* ============ State Variables ============ */

    // Instance of the Controller contract
    IController public controller;

    /* ============ Constructor ============ */

    /**
     * Index state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ External Functions ============ */

    /**
     * Gets the valuation of a IndexToken using data from the price oracle. Reverts
     * if no price exists for a component in the IndexToken. Note: this works for external
     * positions and negative (debt) positions.
     * 
     * Note: There is a risk that the valuation is off if airdrops aren't retrieved or
     * debt builds up via interest and its not reflected in the position
     *
     * @param _indexToken      IndexToken instance to get valuation
     * @param _quoteAsset      Address of token to quote valuation in
     *
     * @return                 IndexToken valuation in terms of quote asset in precise units 1e18
     */
    function calculateIndexTokenValuation(IIndexToken _indexToken, address _quoteAsset) external view returns (uint256) {
        IPriceOracle priceOracle = controller.getPriceOracle();
        address masterQuoteAsset = priceOracle.masterQuoteAsset();
        address[] memory components = _indexToken.getComponents();
        int256 valuation;

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            // Get component price from price oracle. If price does not exist, revert.
            uint256 componentPrice = priceOracle.getPrice(component, masterQuoteAsset);

            int256 aggregateUnits = _indexToken.getTotalComponentRealUnits(component);

            // Normalize each position unit to preciseUnits 1e18 and cast to signed int
            uint256 unitDecimals = ERC20(component).decimals();
            uint256 baseUnits = 10 ** unitDecimals;
            int256 normalizedUnits = aggregateUnits.preciseDiv(baseUnits.toInt256());

            // Calculate valuation of the component. Debt positions are effectively subtracted
            valuation = normalizedUnits.preciseMul(componentPrice.toInt256()).add(valuation);
        }

        if (masterQuoteAsset != _quoteAsset) {
            uint256 quoteToMaster = priceOracle.getPrice(_quoteAsset, masterQuoteAsset);
            valuation = valuation.preciseDiv(quoteToMaster.toInt256());
        }

        return valuation.toUint256();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IIndexToken } from "../../interfaces/IIndexToken.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";

/**
 * @title IssuanceValidationUtils
 *
 * A collection of utility functions to help during issuance/redemption of IndexToken.
 */
library IssuanceValidationUtils {
    using SafeMath for uint256;
    using SafeCast for int256;
    using PreciseUnitMath for uint256;

    /**
     * Validates component transfer IN to IndexToken during issuance/redemption. Reverts if Set is undercollateralized post transfer.
     * NOTE: Call this function immediately after transfer IN but before calling external hooks (if any).
     *
     * @param _indexToken             Instance of the IndexToken being issued/redeemed
     * @param _component            Address of component being transferred in/out
     * @param _initialSetSupply     Initial IndexToken supply before issuance/redemption
     * @param _componentQuantity    Amount of component transferred into IndexToken
     */
    function validateCollateralizationPostTransferInPreHook(
        IIndexToken _indexToken, 
        address _component, 
        uint256 _initialSetSupply,
        uint256 _componentQuantity
    )
        internal
        view
    {
        uint256 newComponentBalance = IERC20(_component).balanceOf(address(_indexToken));

        uint256 defaultPositionUnit = _indexToken.getDefaultPositionRealUnit(address(_component)).toUint256();
        
        require(
            // Use preciseMulCeil to increase the lower bound and maintain over-collateralization
            newComponentBalance >= _initialSetSupply.preciseMulCeil(defaultPositionUnit).add(_componentQuantity),
            "Invalid transfer in. Results in undercollateralization"
        );
    }

    /**
     * Validates component transfer OUT of IndexToken during issuance/redemption. Reverts if Set is undercollateralized post transfer.
     *
     * @param _indexToken         Instance of the IndexToken being issued/redeemed
     * @param _component        Address of component being transferred in/out
     * @param _finalSetSupply   Final IndexToken supply after issuance/redemption
     */
    function validateCollateralizationPostTransferOut(
        IIndexToken _indexToken, 
        address _component, 
        uint256 _finalSetSupply
    )
        internal 
        view 
    {
        uint256 newComponentBalance = IERC20(_component).balanceOf(address(_indexToken));

        uint256 defaultPositionUnit = _indexToken.getDefaultPositionRealUnit(address(_component)).toUint256();

        require(
            // Use preciseMulCeil to increase lower bound and maintain over-collateralization
            newComponentBalance >= _finalSetSupply.preciseMulCeil(defaultPositionUnit),
            "Invalid transfer out. Results in undercollateralization"
        );
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IController } from "../interfaces/IController.sol";
import { IModule } from "../interfaces/IModule.sol";
import { IIndexToken } from "../interfaces/IIndexToken.sol";
import { Position } from "./lib/Position.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";


/**
 * @title IndexToken
 *
 * ERC20 Token contract that allows privileged modules to make modifications to its positions and invoke function calls
 * from the IndexToken. 
 */
contract IndexToken is ERC20 {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for int256;
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Constants ============ */

    /*
        The PositionState is the status of the Position, whether it is Default (held on the IndexToken)
        or otherwise held on a separate smart contract (whether a module or external source).
        There are issues with cross-usage of enums, so we are defining position states
        as a uint8.
    */
    uint8 internal constant DEFAULT = 0;
    uint8 internal constant EXTERNAL = 1;

    /* ============ Events ============ */

    event Invoked(address indexed _target, uint indexed _value, bytes _data, bytes _returnValue);
    event ModuleAdded(address indexed _module);
    event ModuleRemoved(address indexed _module);    
    event ModuleInitialized(address indexed _module);
    event ManagerEdited(address _newManager, address _oldManager);
    event PendingModuleRemoved(address indexed _module);
    event PositionMultiplierEdited(int256 _newMultiplier);
    event ComponentAdded(address indexed _component);
    event ComponentRemoved(address indexed _component);
    event DefaultPositionUnitEdited(address indexed _component, int256 _realUnit);
    event ExternalPositionUnitEdited(address indexed _component, address indexed _positionModule, int256 _realUnit);
    event ExternalPositionDataEdited(address indexed _component, address indexed _positionModule, bytes _data);
    event PositionModuleAdded(address indexed _component, address indexed _positionModule);
    event PositionModuleRemoved(address indexed _component, address indexed _positionModule);

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not a IndexToken's module or module not enabled
     */
    modifier onlyModule() {
        // Internal function used to reduce bytecode size
        _validateOnlyModule();
        _;
    }

    /**
     * Throws if the sender is not the IndexToken's manager
     */
    modifier onlyManager() {
        _validateOnlyManager();
        _;
    }

    /**
     * Throws if IndexToken is locked and called by any account other than the locker.
     */
    modifier whenLockedOnlyLocker() {
        _validateWhenLockedOnlyLocker();
        _;
    }

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    // The manager has the privelege to add modules, remove, and set a new manager
    address public manager;

    // A module that has locked other modules from privileged functionality, typically required
    // for multi-block module actions such as auctions
    address public locker;

    // List of initialized Modules; Modules extend the functionality of IndexTokens
    address[] public modules;

    // Modules are initialized from NONE -> PENDING -> INITIALIZED through the
    // addModule (called by manager) and initialize  (called by module) functions
    mapping(address => IIndexToken.ModuleState) public moduleStates;

    // When locked, only the locker (a module) can call privileged functionality
    // Typically utilized if a module (e.g. Auction) needs multiple transactions to complete an action
    // without interruption
    bool public isLocked;

    // List of components
    address[] public components;

    // Mapping that stores all Default and External position information for a given component.
    // Position quantities are represented as virtual units; Default positions are on the top-level,
    // while external positions are stored in a module array and accessed through its externalPositions mapping
    mapping(address => IIndexToken.ComponentPosition) private componentPositions;

    // The multiplier applied to the virtual position unit to achieve the real/actual unit.
    // This multiplier is used for efficiently modifying the entire position units (e.g. streaming fee)
    int256 public positionMultiplier;

    /* ============ Constructor ============ */

    /**
     * When a new IndexToken is created, initializes Positions in default state and adds modules into pending state.
     * All parameter validations are on the IndexTokenCreator contract. Validations are performed already on the 
     * IndexTokenCreator. Initiates the positionMultiplier as 1e18 (no adjustments).
     *
     * @param _components             List of addresses of components for initial Positions
     * @param _units                  List of units. Each unit is the # of components per 10^18 of a IndexToken
     * @param _modules                List of modules to enable. All modules must be approved by the Controller
     * @param _controller             Address of the controller
     * @param _manager                Address of the manager
     * @param _name                   Name of the IndexToken
     * @param _symbol                 Symbol of the IndexToken
     */
    constructor(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        IController _controller,
        address _manager,
        string memory _name,
        string memory _symbol
    )
        public
        ERC20(_name, _symbol)
    {
        controller = _controller;
        manager = _manager;
        positionMultiplier = PreciseUnitMath.preciseUnitInt();
        components = _components;

        // Modules are put in PENDING state, as they need to be individually initialized by the Module
        for (uint256 i = 0; i < _modules.length; i++) {
            moduleStates[_modules[i]] = IIndexToken.ModuleState.PENDING;
        }

        // Positions are put in default state initially
        for (uint256 j = 0; j < _components.length; j++) {
            componentPositions[_components[j]].virtualUnit = _units[j];
        }
    }

    /* ============ External Functions ============ */

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that allows a module to make an arbitrary function
     * call to any contract.
     *
     * @param _target                 Address of the smart contract to call
     * @param _value                  Quantity of Ether to provide the call (typically 0)
     * @param _data                   Encoded function selector and arguments
     * @return _returnValue           Bytes encoded return value
     */
    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyModule
        whenLockedOnlyLocker
        returns (bytes memory _returnValue)
    {
        _returnValue = _target.functionCallWithValue(_data, _value);

        emit Invoked(_target, _value, _data, _returnValue);

        return _returnValue;
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that adds a component to the components array.
     */
    function addComponent(address _component) external onlyModule whenLockedOnlyLocker {
        require(!isComponent(_component), "Must not be component");
        
        components.push(_component);

        emit ComponentAdded(_component);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that removes a component from the components array.
     */
    function removeComponent(address _component) external onlyModule whenLockedOnlyLocker {
        components.removeStorage(_component);

        emit ComponentRemoved(_component);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that edits a component's virtual unit. Takes a real unit
     * and converts it to virtual before committing.
     */
    function editDefaultPositionUnit(address _component, int256 _realUnit) external onlyModule whenLockedOnlyLocker {
        int256 virtualUnit = _convertRealToVirtualUnit(_realUnit);

        componentPositions[_component].virtualUnit = virtualUnit;

        emit DefaultPositionUnitEdited(_component, _realUnit);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that adds a module to a component's externalPositionModules array
     */
    function addExternalPositionModule(address _component, address _positionModule) external onlyModule whenLockedOnlyLocker {
        require(!isExternalPositionModule(_component, _positionModule), "Module already added");

        componentPositions[_component].externalPositionModules.push(_positionModule);

        emit PositionModuleAdded(_component, _positionModule);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that removes a module from a component's 
     * externalPositionModules array and deletes the associated externalPosition.
     */
    function removeExternalPositionModule(
        address _component,
        address _positionModule
    )
        external
        onlyModule
        whenLockedOnlyLocker
    {
        componentPositions[_component].externalPositionModules.removeStorage(_positionModule);

        delete componentPositions[_component].externalPositions[_positionModule];

        emit PositionModuleRemoved(_component, _positionModule);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that edits a component's external position virtual unit. 
     * Takes a real unit and converts it to virtual before committing.
     */
    function editExternalPositionUnit(
        address _component,
        address _positionModule,
        int256 _realUnit
    )
        external
        onlyModule
        whenLockedOnlyLocker
    {
        int256 virtualUnit = _convertRealToVirtualUnit(_realUnit);

        componentPositions[_component].externalPositions[_positionModule].virtualUnit = virtualUnit;

        emit ExternalPositionUnitEdited(_component, _positionModule, _realUnit);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that edits a component's external position data
     */
    function editExternalPositionData(
        address _component,
        address _positionModule,
        bytes calldata _data
    )
        external
        onlyModule
        whenLockedOnlyLocker
    {
        componentPositions[_component].externalPositions[_positionModule].data = _data;

        emit ExternalPositionDataEdited(_component, _positionModule, _data);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Modifies the position multiplier. This is typically used to efficiently
     * update all the Positions' units at once in applications where inflation is awarded (e.g. subscription fees).
     */
    function editPositionMultiplier(int256 _newMultiplier) external onlyModule whenLockedOnlyLocker {        
        _validateNewMultiplier(_newMultiplier);

        positionMultiplier = _newMultiplier;

        emit PositionMultiplierEdited(_newMultiplier);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Increases the "account" balance by the "quantity".
     */
    function mint(address _account, uint256 _quantity) external onlyModule whenLockedOnlyLocker {
        _mint(_account, _quantity);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Decreases the "account" balance by the "quantity".
     * _burn checks that the "account" already has the required "quantity".
     */
    function burn(address _account, uint256 _quantity) external onlyModule whenLockedOnlyLocker {
        _burn(_account, _quantity);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. When a IndexToken is locked, only the locker can call privileged functions.
     */
    function lock() external onlyModule {
        require(!isLocked, "Must not be locked");
        locker = msg.sender;
        isLocked = true;
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Unlocks the IndexToken and clears the locker
     */
    function unlock() external onlyModule {
        require(isLocked, "Must be locked");
        require(locker == msg.sender, "Must be locker");
        delete locker;
        isLocked = false;
    }

    /**
     * MANAGER ONLY. Adds a module into a PENDING state; Module must later be initialized via 
     * module's initialize function
     */
    function addModule(address _module) external onlyManager {
        require(moduleStates[_module] == IIndexToken.ModuleState.NONE, "Module must not be added");
        require(controller.isModule(_module), "Must be enabled on Controller");

        moduleStates[_module] = IIndexToken.ModuleState.PENDING;

        emit ModuleAdded(_module);
    }

    /**
     * MANAGER ONLY. Removes a module from the IndexToken. IndexToken calls removeModule on module itself to confirm
     * it is not needed to manage any remaining positions and to remove state.
     */
    function removeModule(address _module) external onlyManager {
        require(!isLocked, "Only when unlocked");
        require(moduleStates[_module] == IIndexToken.ModuleState.INITIALIZED, "Module must be added");

        IModule(_module).removeModule();

        moduleStates[_module] = IIndexToken.ModuleState.NONE;

        modules.removeStorage(_module);

        emit ModuleRemoved(_module);
    }

    /**
     * MANAGER ONLY. Removes a pending module from the IndexToken.
     */
    function removePendingModule(address _module) external onlyManager {
        require(!isLocked, "Only when unlocked");
        require(moduleStates[_module] == IIndexToken.ModuleState.PENDING, "Module must be pending");

        moduleStates[_module] = IIndexToken.ModuleState.NONE;

        emit PendingModuleRemoved(_module);
    }

    /**
     * Initializes an added module from PENDING to INITIALIZED state. Can only call when unlocked.
     * An address can only enter a PENDING state if it is an enabled module added by the manager.
     * Only callable by the module itself, hence msg.sender is the subject of update.
     */
    function initializeModule() external {
        require(!isLocked, "Only when unlocked");
        require(moduleStates[msg.sender] == IIndexToken.ModuleState.PENDING, "Module must be pending");
        
        moduleStates[msg.sender] = IIndexToken.ModuleState.INITIALIZED;
        modules.push(msg.sender);

        emit ModuleInitialized(msg.sender);
    }

    /**
     * MANAGER ONLY. Changes manager; We allow null addresses in case the manager wishes to wind down the IndexToken.
     * Modules may rely on the manager state, so only changable when unlocked
     */
    function setManager(address _manager) external onlyManager {
        require(!isLocked, "Only when unlocked");
        address oldManager = manager;
        manager = _manager;

        emit ManagerEdited(_manager, oldManager);
    }

    /* ============ External Getter Functions ============ */

    function getComponents() external view returns(address[] memory) {
        return components;
    }

    function getDefaultPositionRealUnit(address _component) public view returns(int256) {
        return _convertVirtualToRealUnit(_defaultPositionVirtualUnit(_component));
    }

    function getExternalPositionRealUnit(address _component, address _positionModule) public view returns(int256) {
        return _convertVirtualToRealUnit(_externalPositionVirtualUnit(_component, _positionModule));
    }

    function getExternalPositionModules(address _component) external view returns(address[] memory) {
        return _externalPositionModules(_component);
    }

    function getExternalPositionData(address _component,address _positionModule) external view returns(bytes memory) {
        return _externalPositionData(_component, _positionModule);
    }

    function getModules() external view returns (address[] memory) {
        return modules;
    }

    function isComponent(address _component) public view returns(bool) {
        return components.contains(_component);
    }

    function isExternalPositionModule(address _component, address _module) public view returns(bool) {
        return _externalPositionModules(_component).contains(_module);
    }

    /**
     * Only ModuleStates of INITIALIZED modules are considered enabled
     */
    function isInitializedModule(address _module) external view returns (bool) {
        return moduleStates[_module] == IIndexToken.ModuleState.INITIALIZED;
    }

    /**
     * Returns whether the module is in a pending state
     */
    function isPendingModule(address _module) external view returns (bool) {
        return moduleStates[_module] == IIndexToken.ModuleState.PENDING;
    }

    /**
     * Returns a list of Positions, through traversing the components. Each component with a non-zero virtual unit
     * is considered a Default Position, and each externalPositionModule will generate a unique position.
     * Virtual units are converted to real units. This function is typically used off-chain for data presentation purposes.
     */
    function getPositions() external view returns (IIndexToken.Position[] memory) {
        IIndexToken.Position[] memory positions = new IIndexToken.Position[](_getPositionCount());
        uint256 positionCount = 0;

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];

            // A default position exists if the default virtual unit is > 0
            if (_defaultPositionVirtualUnit(component) > 0) {
                positions[positionCount] = IIndexToken.Position({
                    component: component,
                    module: address(0),
                    unit: getDefaultPositionRealUnit(component),
                    positionState: DEFAULT,
                    data: ""
                });

                positionCount++;
            }

            address[] memory externalModules = _externalPositionModules(component);
            for (uint256 j = 0; j < externalModules.length; j++) {
                address currentModule = externalModules[j];

                positions[positionCount] = IIndexToken.Position({
                    component: component,
                    module: currentModule,
                    unit: getExternalPositionRealUnit(component, currentModule),
                    positionState: EXTERNAL,
                    data: _externalPositionData(component, currentModule)
                });

                positionCount++;
            }
        }

        return positions;
    }

    /**
     * Returns the total Real Units for a given component, summing the default and external position units.
     */
    function getTotalComponentRealUnits(address _component) external view returns(int256) {
        int256 totalUnits = getDefaultPositionRealUnit(_component);

        address[] memory externalModules = _externalPositionModules(_component);
        for (uint256 i = 0; i < externalModules.length; i++) {
            // We will perform the summation no matter what, as an external position virtual unit can be negative
            totalUnits = totalUnits.add(getExternalPositionRealUnit(_component, externalModules[i]));
        }

        return totalUnits;
    }


    receive() external payable {} // solium-disable-line quotes

    /* ============ Internal Functions ============ */

    function _defaultPositionVirtualUnit(address _component) internal view returns(int256) {
        return componentPositions[_component].virtualUnit;
    }

    function _externalPositionModules(address _component) internal view returns(address[] memory) {
        return componentPositions[_component].externalPositionModules;
    }

    function _externalPositionVirtualUnit(address _component, address _module) internal view returns(int256) {
        return componentPositions[_component].externalPositions[_module].virtualUnit;
    }

    function _externalPositionData(address _component, address _module) internal view returns(bytes memory) {
        return componentPositions[_component].externalPositions[_module].data;
    }

    /**
     * Takes a real unit and divides by the position multiplier to return the virtual unit. Negative units will
     * be rounded away from 0 so no need to check that unit will be rounded down to 0 in conversion.
     */
    function _convertRealToVirtualUnit(int256 _realUnit) internal view returns(int256) {
        int256 virtualUnit = _realUnit.conservativePreciseDiv(positionMultiplier);

        // This check ensures that the virtual unit does not return a result that has rounded down to 0
        if (_realUnit > 0 && virtualUnit == 0) {
            revert("Real to Virtual unit conversion invalid");
        }

        // This check ensures that when converting back to realUnits the unit won't be rounded down to 0
        if (_realUnit > 0 && _convertVirtualToRealUnit(virtualUnit) == 0) {
            revert("Virtual to Real unit conversion invalid");
        }

        return virtualUnit;
    }

    /**
     * Takes a virtual unit and multiplies by the position multiplier to return the real unit
     */
    function _convertVirtualToRealUnit(int256 _virtualUnit) internal view returns(int256) {
        return _virtualUnit.conservativePreciseMul(positionMultiplier);
    }

    /**
     * To prevent virtual to real unit conversion issues (where real unit may be 0), the 
     * product of the positionMultiplier and the lowest absolute virtualUnit value (across default and
     * external positions) must be greater than 0.
     */
    function _validateNewMultiplier(int256 _newMultiplier) internal view {
        int256 minVirtualUnit = _getPositionsAbsMinimumVirtualUnit();

        require(minVirtualUnit.conservativePreciseMul(_newMultiplier) > 0, "New multiplier too small");
    }

    /**
     * Loops through all of the positions and returns the smallest absolute value of 
     * the virtualUnit.
     *
     * @return Min virtual unit across positions denominated as int256
     */
    function _getPositionsAbsMinimumVirtualUnit() internal view returns(int256) {
        // Additional assignment happens in the loop below
        uint256 minimumUnit = uint256(-1);

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];

            // A default position exists if the default virtual unit is > 0
            uint256 defaultUnit = _defaultPositionVirtualUnit(component).toUint256();
            if (defaultUnit > 0 && defaultUnit < minimumUnit) {
                minimumUnit = defaultUnit;
            }

            address[] memory externalModules = _externalPositionModules(component);
            for (uint256 j = 0; j < externalModules.length; j++) {
                address currentModule = externalModules[j];

                uint256 virtualUnit = _absoluteValue(
                    _externalPositionVirtualUnit(component, currentModule)
                );
                if (virtualUnit > 0 && virtualUnit < minimumUnit) {
                    minimumUnit = virtualUnit;
                }
            }
        }

        return minimumUnit.toInt256();        
    }

    /**
     * Gets the total number of positions, defined as the following:
     * - Each component has a default position if its virtual unit is > 0
     * - Each component's external positions module is counted as a position
     */
    function _getPositionCount() internal view returns (uint256) {
        uint256 positionCount;
        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];

            // Increment the position count if the default position is > 0
            if (_defaultPositionVirtualUnit(component) > 0) {
                positionCount++;
            }

            // Increment the position count by each external position module
            address[] memory externalModules = _externalPositionModules(component);
            if (externalModules.length > 0) {
                positionCount = positionCount.add(externalModules.length);  
            }
        }

        return positionCount;
    }

    /**
     * Returns the absolute value of the signed integer value
     * @param _a Signed interger value
     * @return Returns the absolute value in uint256
     */
    function _absoluteValue(int256 _a) internal pure returns(uint256) {
        return _a >= 0 ? _a.toUint256() : (-_a).toUint256();
    }

    /**
     * Due to reason error bloat, internal functions are used to reduce bytecode size
     *
     * Module must be initialized on the IndexToken and enabled by the controller
     */
    function _validateOnlyModule() internal view {
        require(
            moduleStates[msg.sender] == IIndexToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    function _validateOnlyManager() internal view {
        require(msg.sender == manager, "Only manager can call");
    }

    function _validateWhenLockedOnlyLocker() internal view {
        if (isLocked) {
            require(msg.sender == locker, "When locked, only the locker can call");
        }
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IController } from "../interfaces/IController.sol";
import { IndexToken } from "./IndexToken.sol";
import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";

/**
 * @title IndexTokenCreator
 *
 * IndexTokenCreator is a smart contract used to deploy new IndexToken contracts. The IndexTokenCreator
 * is a Factory contract that is enabled by the controller to create and register new IndexTokens.
 */
contract IndexTokenCreator {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event IndexTokenCreated(address indexed _indexToken, address _manager, string _name, string _symbol);

    /* ============ State Variables ============ */

    // Instance of the controller smart contract
    IController public controller;

    /* ============ Functions ============ */

    /**
     * @param _controller          Instance of the controller
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /**
     * Creates a IndexToken smart contract and registers the IndexToken with the controller. The IndexTokens are composed
     * of positions that are instantiated as DEFAULT (positionState = 0) state.
     *
     * @param _components             List of addresses of components for initial Positions
     * @param _units                  List of units. Each unit is the # of components per 10^18 of a IndexToken
     * @param _modules                List of modules to enable. All modules must be approved by the Controller
     * @param _manager                Address of the manager
     * @param _name                   Name of the IndexToken
     * @param _symbol                 Symbol of the IndexToken
     * @return address                Address of the newly created IndexToken
     */
    function create(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        address _manager,
        string memory _name,
        string memory _symbol
    )
        external
        returns (address)
    {
        require(_components.length > 0, "Must have at least 1 component");
        require(_components.length == _units.length, "Component and unit lengths must be the same");
        require(!_components.hasDuplicate(), "Components must not have a duplicate");
        require(_modules.length > 0, "Must have at least 1 module");
        require(_manager != address(0), "Manager must not be empty");

        for (uint256 i = 0; i < _components.length; i++) {
            require(_components[i] != address(0), "Component must not be null address");
            require(_units[i] > 0, "Units must be greater than 0");
        }

        for (uint256 j = 0; j < _modules.length; j++) {
            require(controller.isModule(_modules[j]), "Must be enabled module");
        }

        // Creates a new IndexToken instance
        IndexToken indexToken = new IndexToken(
            _components,
            _units,
            _modules,
            controller,
            _manager,
            _name,
            _symbol
        );

        // Registers Index with controller
        controller.addIndex(address(indexToken));

        emit IndexTokenCreated(address(indexToken), _manager, _name, _symbol);

        return address(indexToken);
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";


/**
 * @title Controller
 *
 * Contract that houses state for approvals and system contracts such as added Indexs,
 * modules, factories, resources (like price oracles), and protocol fee configurations.
 */
contract Controller is Ownable {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event FactoryAdded(address indexed _factory);
    event FactoryRemoved(address indexed _factory);
    event FeeEdited(address indexed _module, uint256 indexed _feeType, uint256 _feePercentage);
    event FeeRecipientChanged(address _newFeeRecipient);
    event ModuleAdded(address indexed _module);
    event ModuleRemoved(address indexed _module);
    event ResourceAdded(address indexed _resource, uint256 _id);
    event ResourceRemoved(address indexed _resource, uint256 _id);
    event IndexAdded(address indexed _indexToken, address indexed _factory);
    event IndexRemoved(address indexed _indexToken);

    /* ============ Modifiers ============ */

    /**
     * Throws if function is called by any address other than a valid factory.
     */
    modifier onlyFactory() {
        require(isFactory[msg.sender], "Only valid factories can call");
        _;
    }

    modifier onlyInitialized() {
        require(isInitialized, "Contract must be initialized.");
        _;
    }

    /* ============ State Variables ============ */

    // List of enabled Indexs
    address[] public indexs;
    // List of enabled factories of IndexTokens
    address[] public factories;
    // List of enabled Modules; Modules extend the functionality of IndexTokens
    address[] public modules;
    // List of enabled Resources; Resources provide data, functionality, or
    // permissions that can be drawn upon from Module, IndexTokens or factories
    address[] public resources;

    // Mappings to check whether address is valid Index, Factory, Module or Resource
    mapping(address => bool) public isIndex;
    mapping(address => bool) public isFactory;
    mapping(address => bool) public isModule;
    mapping(address => bool) public isResource;

    // Mapping of modules to fee types to fee percentage. A module can have multiple feeTypes
    // Fee is denominated in precise unit percentages (100% = 1e18, 1% = 1e16)
    mapping(address => mapping(uint256 => uint256)) public fees;

    // Mapping of resource ID to resource address, which allows contracts to fetch the correct
    // resource while providing an ID
    mapping(uint256 => address) public resourceId;

    // Recipient of protocol fees
    address public feeRecipient;

    // Return true if the controller is initialized
    bool public isInitialized;

    /* ============ Constructor ============ */

    /**
     * Initializes the initial fee recipient on deployment.
     *
     * @param _feeRecipient          Address of the initial protocol fee recipient
     */
    constructor(address _feeRecipient) public {
        feeRecipient = _feeRecipient;
    }

    /* ============ External Functions ============ */

    /**
     * Initializes any predeployed factories, modules, and resources post deployment. Note: This function can
     * only be called by the owner once to batch initialize the initial system contracts.
     *
     * @param _factories             List of factories to add
     * @param _modules               List of modules to add
     * @param _resources             List of resources to add
     * @param _resourceIds           List of resource IDs associated with the resources
     */
    function initialize(
        address[] memory _factories,
        address[] memory _modules,
        address[] memory _resources,
        uint256[] memory _resourceIds
    )
        external
        onlyOwner
    {
        require(!isInitialized, "Controller is already initialized");
        require(_resources.length == _resourceIds.length, "Array lengths do not match.");

        factories = _factories;
        modules = _modules;
        resources = _resources;

        // Loop through and initialize isModule, isFactory, and isResource mapping
        for (uint256 i = 0; i < _factories.length; i++) {
            require(_factories[i] != address(0), "Zero address submitted.");
            isFactory[_factories[i]] = true;
        }
        for (uint256 i = 0; i < _modules.length; i++) {
            require(_modules[i] != address(0), "Zero address submitted.");
            isModule[_modules[i]] = true;
        }

        for (uint256 i = 0; i < _resources.length; i++) {
            require(_resources[i] != address(0), "Zero address submitted.");
            require(resourceId[_resourceIds[i]] == address(0), "Resource ID already exists");
            isResource[_resources[i]] = true;
            resourceId[_resourceIds[i]] = _resources[i];
        }

        // Index to true to only allow initialization once
        isInitialized = true;
    }

    /**
     * PRIVILEGED FACTORY FUNCTION. Adds a newly deployed IndexToken as an enabled IndexToken.
     *
     * @param _indexToken               Address of the IndexToken contract to add
     */
    function addIndex(address _indexToken) external onlyInitialized onlyFactory {
        require(!isIndex[_indexToken], "Index already exists");

        isIndex[_indexToken] = true;

        indexs.push(_indexToken);

        emit IndexAdded(_indexToken, msg.sender);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a Index
     *
     * @param _indexToken               Address of the IndexToken contract to remove
     */
    function removeIndex(address _indexToken) external onlyInitialized onlyOwner {
        require(isIndex[_indexToken], "Index does not exist");

        indexs = indexs.remove(_indexToken);

        isIndex[_indexToken] = false;

        emit IndexRemoved(_indexToken);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a factory
     *
     * @param _factory               Address of the factory contract to add
     */
    function addFactory(address _factory) external onlyInitialized onlyOwner {
        require(!isFactory[_factory], "Factory already exists");

        isFactory[_factory] = true;

        factories.push(_factory);

        emit FactoryAdded(_factory);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a factory
     *
     * @param _factory               Address of the factory contract to remove
     */
    function removeFactory(address _factory) external onlyInitialized onlyOwner {
        require(isFactory[_factory], "Factory does not exist");

        factories = factories.remove(_factory);

        isFactory[_factory] = false;

        emit FactoryRemoved(_factory);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a module
     *
     * @param _module               Address of the module contract to add
     */
    function addModule(address _module) external onlyInitialized onlyOwner {
        require(!isModule[_module], "Module already exists");

        isModule[_module] = true;

        modules.push(_module);

        emit ModuleAdded(_module);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a module
     *
     * @param _module               Address of the module contract to remove
     */
    function removeModule(address _module) external onlyInitialized onlyOwner {
        require(isModule[_module], "Module does not exist");

        modules = modules.remove(_module);

        isModule[_module] = false;

        emit ModuleRemoved(_module);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a resource
     *
     * @param _resource               Address of the resource contract to add
     * @param _id                     New ID of the resource contract
     */
    function addResource(address _resource, uint256 _id) external onlyInitialized onlyOwner {
        require(!isResource[_resource], "Resource already exists");

        require(resourceId[_id] == address(0), "Resource ID already exists");

        isResource[_resource] = true;

        resourceId[_id] = _resource;

        resources.push(_resource);

        emit ResourceAdded(_resource, _id);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a resource
     *
     * @param _id               ID of the resource contract to remove
     */
    function removeResource(uint256 _id) external onlyInitialized onlyOwner {
        address resourceToRemove = resourceId[_id];

        require(resourceToRemove != address(0), "Resource does not exist");

        resources = resources.remove(resourceToRemove);

        delete resourceId[_id];

        isResource[resourceToRemove] = false;

        emit ResourceRemoved(resourceToRemove, _id);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a fee to a module
     *
     * @param _module               Address of the module contract to add fee to
     * @param _feeType              Type of the fee to add in the module
     * @param _newFeePercentage     Percentage of fee to add in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function addFee(address _module, uint256 _feeType, uint256 _newFeePercentage) external onlyInitialized onlyOwner {
        require(isModule[_module], "Module does not exist");

        require(fees[_module][_feeType] == 0, "Fee type already exists on module");

        fees[_module][_feeType] = _newFeePercentage;

        emit FeeEdited(_module, _feeType, _newFeePercentage);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit a fee in an existing module
     *
     * @param _module               Address of the module contract to edit fee
     * @param _feeType              Type of the fee to edit in the module
     * @param _newFeePercentage     Percentage of fee to edit in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function editFee(address _module, uint256 _feeType, uint256 _newFeePercentage) external onlyInitialized onlyOwner {
        require(isModule[_module], "Module does not exist");

        require(fees[_module][_feeType] != 0, "Fee type does not exist on module");

        fees[_module][_feeType] = _newFeePercentage;

        emit FeeEdited(_module, _feeType, _newFeePercentage);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol fee recipient
     *
     * @param _newFeeRecipient      Address of the new protocol fee recipient
     */
    function editFeeRecipient(address _newFeeRecipient) external onlyInitialized onlyOwner {
        require(_newFeeRecipient != address(0), "Address must not be 0");

        feeRecipient = _newFeeRecipient;

        emit FeeRecipientChanged(_newFeeRecipient);
    }

    /* ============ External Getter Functions ============ */

    function getModuleFee(
        address _moduleAddress,
        uint256 _feeType
    )
        external
        view
        returns (uint256)
    {
        return fees[_moduleAddress][_feeType];
    }

    function getFactories() external view returns (address[] memory) {
        return factories;
    }

    function getModules() external view returns (address[] memory) {
        return modules;
    }

    function getResources() external view returns (address[] memory) {
        return resources;
    }

    function getIndices() external view returns (address[] memory) {
        return indexs;
    }

    /**
     * Check if a contract address is a module, Index, resource, factory or controller
     *
     * @param  _contractAddress           The contract address to check
     */
    function isSystemContract(address _contractAddress) external view returns (bool) {
        return (
            isIndex[_contractAddress] ||
            isModule[_contractAddress] ||
            isResource[_contractAddress] ||
            isFactory[_contractAddress] ||
            _contractAddress == address(this)
        );
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { IController } from "../interfaces/IController.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IntegrationRegistry
 *
 * The IntegrationRegistry holds state relating to the Modules and the integrations they are connected with.
 * The state is combined into a single Registry to allow governance updates to be aggregated to one contract.
 */
contract IntegrationRegistry is Ownable {

    /* ============ Events ============ */

    event IntegrationAdded(address indexed _module, address indexed _adapter, string _integrationName);
    event IntegrationRemoved(address indexed _module, address indexed _adapter, string _integrationName);
    event IntegrationEdited(
        address indexed _module,
        address _newAdapter,
        string _integrationName
    );

    /* ============ State Variables ============ */

    // Address of the Controller contract
    IController public controller;

    // Mapping of module => integration identifier => adapter address
    mapping(address => mapping(bytes32 => address)) private integrations;

    /* ============ Constructor ============ */

    /**
     * Initializes the controller
     *
     * @param _controller          Instance of the controller
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ External Functions ============ */

    /**
     * GOVERNANCE FUNCTION: Add a new integration to the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     * @param  _adapter      Address of the adapter contract to add
     */
    function addIntegration(
        address _module,
        string memory _name,
        address _adapter
    )
        public
        onlyOwner
    {
        bytes32 hashedName = _nameHash(_name);
        require(controller.isModule(_module), "Must be valid module.");
        require(integrations[_module][hashedName] == address(0), "Integration exists already.");
        require(_adapter != address(0), "Adapter address must exist.");

        integrations[_module][hashedName] = _adapter;

        emit IntegrationAdded(_module, _adapter, _name);
    }

    /**
     * GOVERNANCE FUNCTION: Batch add new adapters. Reverts if exists on any module and name
     *
     * @param  _modules      Array of addresses of the modules associated with integration
     * @param  _names        Array of human readable strings identifying the integration
     * @param  _adapters     Array of addresses of the adapter contracts to add
     */
    function batchAddIntegration(
        address[] memory _modules,
        string[] memory _names,
        address[] memory _adapters
    )
        external
        onlyOwner
    {
        // Storing modules count to local variable to save on invocation
        uint256 modulesCount = _modules.length;

        require(modulesCount > 0, "Modules must not be empty");
        require(modulesCount == _names.length, "Module and name lengths mismatch");
        require(modulesCount == _adapters.length, "Module and adapter lengths mismatch");

        for (uint256 i = 0; i < modulesCount; i++) {
            // Add integrations to the specified module. Will revert if module and name combination exists
            addIntegration(
                _modules[i],
                _names[i],
                _adapters[i]
            );
        }
    }

    /**
     * GOVERNANCE FUNCTION: Edit an existing integration on the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     * @param  _adapter      Address of the adapter contract to edit
     */
    function editIntegration(
        address _module,
        string memory _name,
        address _adapter
    )
        public
        onlyOwner
    {
        bytes32 hashedName = _nameHash(_name);

        require(controller.isModule(_module), "Must be valid module.");
        require(integrations[_module][hashedName] != address(0), "Integration does not exist.");
        require(_adapter != address(0), "Adapter address must exist.");

        integrations[_module][hashedName] = _adapter;

        emit IntegrationEdited(_module, _adapter, _name);
    }

    /**
     * GOVERNANCE FUNCTION: Batch edit adapters for modules. Reverts if module and
     * adapter name don't map to an adapter address
     *
     * @param  _modules      Array of addresses of the modules associated with integration
     * @param  _names        Array of human readable strings identifying the integration
     * @param  _adapters     Array of addresses of the adapter contracts to add
     */
    function batchEditIntegration(
        address[] memory _modules,
        string[] memory _names,
        address[] memory _adapters
    )
        external
        onlyOwner
    {
        // Storing name count to local variable to save on invocation
        uint256 modulesCount = _modules.length;

        require(modulesCount > 0, "Modules must not be empty");
        require(modulesCount == _names.length, "Module and name lengths mismatch");
        require(modulesCount == _adapters.length, "Module and adapter lengths mismatch");

        for (uint256 i = 0; i < modulesCount; i++) {
            // Edits integrations to the specified module. Will revert if module and name combination does not exist
            editIntegration(
                _modules[i],
                _names[i],
                _adapters[i]
            );
        }
    }

    /**
     * GOVERNANCE FUNCTION: Remove an existing integration on the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     */
    function removeIntegration(address _module, string memory _name) external onlyOwner {
        bytes32 hashedName = _nameHash(_name);
        require(integrations[_module][hashedName] != address(0), "Integration does not exist.");

        address oldAdapter = integrations[_module][hashedName];
        delete integrations[_module][hashedName];

        emit IntegrationRemoved(_module, oldAdapter, _name);
    }

    /* ============ External Getter Functions ============ */

    /**
     * Get integration adapter address associated with passed human readable name
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable adapter name
     *
     * @return               Address of adapter
     */
    function getIntegrationAdapter(address _module, string memory _name) external view returns (address) {
        return integrations[_module][_nameHash(_name)];
    }

    /**
     * Get integration adapter address associated with passed hashed name
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _nameHash     Hash of human readable adapter name
     *
     * @return               Address of adapter
     */
    function getIntegrationAdapterWithHash(address _module, bytes32 _nameHash) external view returns (address) {
        return integrations[_module][_nameHash];
    }

    /**
     * Check if adapter name is valid
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     *
     * @return               Boolean indicating if valid
     */
    function isValidIntegration(address _module, string memory _name) external view returns (bool) {
        return integrations[_module][_nameHash(_name)] != address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * Hashes the string and returns a bytes32 value
     */
    function _nameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";


import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IIndexToken } from "../interfaces/IIndexToken.sol";


/**
 * @title IndexTokenViewer
 *
 * IndexTokenViewer enables batch queries of IndexToken state.
 *
 * UPDATE:
 * - Added getSetDetails functions
 */
contract IndexTokenViewer {

    struct SetDetails {
        string name;
        string symbol;
        address manager;
        address[] modules;
        IIndexToken.ModuleState[] moduleStatuses;
        IIndexToken.Position[] positions;
        uint256 totalSupply;
    }

    function batchFetchManagers(
        IIndexToken[] memory _indexTokens
    )
        external
        view
        returns (address[] memory) 
    {
        address[] memory managers = new address[](_indexTokens.length);

        for (uint256 i = 0; i < _indexTokens.length; i++) {
            managers[i] = _indexTokens[i].manager();
        }
        return managers;
    }

    function batchFetchModuleStates(
        IIndexToken[] memory _indexTokens,
        address[] calldata _modules
    )
        public
        view
        returns (IIndexToken.ModuleState[][] memory)
    {
        IIndexToken.ModuleState[][] memory states = new IIndexToken.ModuleState[][](_indexTokens.length);
        for (uint256 i = 0; i < _indexTokens.length; i++) {
            IIndexToken.ModuleState[] memory moduleStates = new IIndexToken.ModuleState[](_modules.length);
            for (uint256 j = 0; j < _modules.length; j++) {
                moduleStates[j] = _indexTokens[i].moduleStates(_modules[j]);
            }
            states[i] = moduleStates;
        }
        return states;
    }

    function batchFetchDetails(
        IIndexToken[] memory _indexTokens,
        address[] calldata _moduleList
    )
        public
        view
        returns (SetDetails[] memory)
    {
        IIndexToken.ModuleState[][] memory moduleStates = batchFetchModuleStates(_indexTokens, _moduleList);

        SetDetails[] memory details = new SetDetails[](_indexTokens.length);
        for (uint256 i = 0; i < _indexTokens.length; i++) {
            IIndexToken setToken = _indexTokens[i];

            details[i] = SetDetails({
                name: ERC20(address(setToken)).name(),
                symbol: ERC20(address(setToken)).symbol(),
                manager: setToken.manager(),
                modules: setToken.getModules(),
                moduleStatuses: moduleStates[i],
                positions: setToken.getPositions(),
                totalSupply: setToken.totalSupply()
            });
        }
        return details;
    }

    function getSetDetails(
        IIndexToken _indexToken,
        address[] calldata _moduleList
    )
        external
        view
        returns(SetDetails memory)
    {
        IIndexToken[] memory setAddressForBatchFetch = new IIndexToken[](1);
        setAddressForBatchFetch[0] = _indexToken;

        return batchFetchDetails(setAddressForBatchFetch, _moduleList)[0];
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";


import { ERC20Viewer } from "./ERC20Viewer.sol";
import { IndexTokenViewer } from "./IndexTokenViewer.sol";
import { StreamingFeeModuleViewer } from "./StreamingFeeModuleViewer.sol";


/**
 * @title ProtocolViewer
 *
 * ProtocolViewer enables batch queries of various protocol state.
 */
contract ProtocolViewer is
    ERC20Viewer,
    IndexTokenViewer,
    StreamingFeeModuleViewer
{
    constructor() public {}
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;


import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title ERC20Viewer
 *
 * Interfaces for fetching multiple ERC20 state in a single read
 */
contract ERC20Viewer {

    /*
     * Fetches token balances for each tokenAddress, tokenOwner pair
     *
     * @param  _tokenAddresses    Addresses of ERC20 contracts
     * @param  _ownerAddresses    Addresses of users sequential to tokenAddress
     * @return  uint256[]         Array of balances for each ERC20 contract passed in
     */
    function batchFetchBalancesOf(
        address[] calldata _tokenAddresses,
        address[] calldata _ownerAddresses
    )
        public
        view
        returns (uint256[] memory)
    {
        // Cache length of addresses to fetch balances for
        uint256 addressesCount = _tokenAddresses.length;

        // Instantiate output array in memory
        uint256[] memory balances = new uint256[](addressesCount);

        // Cycle through contract addresses array and fetching the balance of each for the owner
        for (uint256 i = 0; i < addressesCount; i++) {
            balances[i] = ERC20(address(_tokenAddresses[i])).balanceOf(_ownerAddresses[i]);
        }

        return balances;
    }

    /*
     * Fetches token allowances for each tokenAddress, tokenOwner tuple
     *
     * @param  _tokenAddresses      Addresses of ERC20 contracts
     * @param  _ownerAddresses      Addresses of owner sequential to tokenAddress
     * @param  _spenderAddresses    Addresses of spenders sequential to tokenAddress
     * @return  uint256[]           Array of allowances for each ERC20 contract passed in
     */
    function batchFetchAllowances(
        address[] calldata _tokenAddresses,
        address[] calldata _ownerAddresses,
        address[] calldata _spenderAddresses
    )
        public
        view
        returns (uint256[] memory)
    {
        // Cache length of addresses to fetch allowances for
        uint256 addressesCount = _tokenAddresses.length;

        // Instantiate output array in memory
        uint256[] memory allowances = new uint256[](addressesCount);

        // Cycle through contract addresses array and fetching the balance of each for the owner
        for (uint256 i = 0; i < addressesCount; i++) {
            allowances[i] = ERC20(address(_tokenAddresses[i])).allowance(_ownerAddresses[i], _spenderAddresses[i]);
        }

        return allowances;
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";


import { IIndexToken } from "../interfaces/IIndexToken.sol";
import { IStreamingFeeModule } from "../interfaces/IStreamingFeeModule.sol";
import { StreamingFeeModule } from "../protocol/modules/StreamingFeeModule.sol";


/**
 * @title StreamingFeeModuleViewer
 *
 * StreamingFeeModuleViewer enables batch queries of StreamingFeeModule state.
 */
contract StreamingFeeModuleViewer {

    struct StreamingFeeInfo {
        address feeRecipient;
        uint256 streamingFeePercentage;
        uint256 unaccruedFees;
    }

    function batchFetchStreamingFeeInfo(
        IStreamingFeeModule _streamingFeeModule,
        IIndexToken[] memory _indexTokens
    )
        external
        view
        returns (StreamingFeeInfo[] memory)
    {
        StreamingFeeInfo[] memory feeInfo = new StreamingFeeInfo[](_indexTokens.length);

        for (uint256 i = 0; i < _indexTokens.length; i++) {
            StreamingFeeModule.FeeState memory feeState = _streamingFeeModule.feeStates(_indexTokens[i]);
            uint256 unaccruedFees = _streamingFeeModule.getFee(_indexTokens[i]);

            feeInfo[i] = StreamingFeeInfo({
                feeRecipient: feeState.feeRecipient,
                streamingFeePercentage: feeState.streamingFeePercentage,
                unaccruedFees: unaccruedFees
            });
        }

        return feeInfo;
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IIndexToken } from "./IIndexToken.sol";
import { StreamingFeeModule } from "../protocol/modules/StreamingFeeModule.sol";

interface IStreamingFeeModule {
    function feeStates(IIndexToken _indexToken) external view returns (StreamingFeeModule.FeeState memory);
    function getFee(IIndexToken _indexToken) external view returns (uint256);
}

// SPDX-License-Identifier: Apache License, Version 2.0


pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IController } from "../../interfaces/IController.sol";
import { IIndexToken } from "../../interfaces/IIndexToken.sol";
import { ModuleBase } from "../lib/ModuleBase.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";


/**
 * @title StreamingFeeModule
 
 *
 * Smart contract that accrues streaming fees for Set managers. Streaming fees are denominated as percent
 * per year and realized as Set inflation rewarded to the manager.
 */
contract StreamingFeeModule is ModuleBase, ReentrancyGuard {
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeCast for uint256;

    using SignedSafeMath for int256;
    using PreciseUnitMath for int256;
    using SafeCast for int256;


    /* ============ Structs ============ */

    struct FeeState {
        address feeRecipient;                   // Address to accrue fees to
        uint256 maxStreamingFeePercentage;      // Max streaming fee maanager commits to using (1% = 1e16, 100% = 1e18)
        uint256 streamingFeePercentage;         // Percent of Set accruing to manager annually (1% = 1e16, 100% = 1e18)
        uint256 lastStreamingFeeTimestamp;      // Timestamp last streaming fee was accrued
    }

    /* ============ Events ============ */

    event FeeActualized(address indexed _indexToken, uint256 _managerFee, uint256 _protocolFee);
    event StreamingFeeUpdated(address indexed _indexToken, uint256 _newStreamingFee);
    event FeeRecipientUpdated(address indexed _indexToken, address _newFeeRecipient);

    /* ============ Constants ============ */

    uint256 private constant ONE_YEAR_IN_SECONDS = 365.25 days;
    uint256 private constant PROTOCOL_STREAMING_FEE_INDEX = 0;

    /* ============ State Variables ============ */

    mapping(IIndexToken => FeeState) public feeStates;

    /* ============ Constructor ============ */

    constructor(IController _controller) public ModuleBase(_controller) {}

    /* ============ External Functions ============ */

    /*
     * Calculates total inflation percentage then mints new Sets to the fee recipient. Position units are
     * then adjusted down (in magnitude) in order to ensure full collateralization. Callable by anyone.
     *
     * @param _indexToken       Address of IndexToken
     */
    function accrueFee(IIndexToken _indexToken) public nonReentrant onlyValidAndInitializedIndex(_indexToken) {
        uint256 managerFee;
        uint256 protocolFee;

        if (_streamingFeePercentage(_indexToken) > 0) {
            uint256 inflationFeePercentage = _calculateStreamingFee(_indexToken);

            // Calculate incentiveFee inflation
            uint256 feeQuantity = _calculateStreamingFeeInflation(_indexToken, inflationFeePercentage);

            // Mint new Sets to manager and protocol
            (
                managerFee,
                protocolFee
            ) = _mintManagerAndProtocolFee(_indexToken, feeQuantity);

            _editPositionMultiplier(_indexToken, inflationFeePercentage);
        }

        feeStates[_indexToken].lastStreamingFeeTimestamp = block.timestamp;

        emit FeeActualized(address(_indexToken), managerFee, protocolFee);
    }

    /**
     * SET MANAGER ONLY. Initialize module with IndexToken and set the fee state for the IndexToken. Passed
     * _settings will have lastStreamingFeeTimestamp over-written.
     *
     * @param _indexToken                 Address of IndexToken
     * @param _settings                 FeeState struct defining fee parameters
     */
    function initialize(
        IIndexToken _indexToken,
        FeeState memory _settings
    )
        external
        onlyIndexManager(_indexToken, msg.sender)
        onlyValidAndPendingIndex(_indexToken)
    {
        require(_settings.feeRecipient != address(0), "Fee Recipient must be non-zero address.");
        require(_settings.maxStreamingFeePercentage < PreciseUnitMath.preciseUnit(), "Max fee must be < 100%.");
        require(_settings.streamingFeePercentage <= _settings.maxStreamingFeePercentage, "Fee must be <= max.");

        _settings.lastStreamingFeeTimestamp = block.timestamp;

        feeStates[_indexToken] = _settings;
        _indexToken.initializeModule();
    }

    /**
     * Removes this module from the IndexToken, via call by the IndexToken. Manager's feeState is deleted. Fees
     * are not accrued in case reason for removing module is related to fee accrual.
     */
    function removeModule() external override {
        delete feeStates[IIndexToken(msg.sender)];
    }

    /*
     * Set new streaming fee. Fees accrue at current rate then new rate is set.
     * Fees are accrued to prevent the manager from unfairly accruing a larger percentage.
     *
     * @param _indexToken       Address of IndexToken
     * @param _newFee         New streaming fee 18 decimal precision
     */
    function updateStreamingFee(
        IIndexToken _indexToken,
        uint256 _newFee
    )
        external
        onlyIndexManager(_indexToken, msg.sender)
        onlyValidAndInitializedIndex(_indexToken)
    {
        require(_newFee < _maxStreamingFeePercentage(_indexToken), "Fee must be less than max");
        accrueFee(_indexToken);

        feeStates[_indexToken].streamingFeePercentage = _newFee;

        emit StreamingFeeUpdated(address(_indexToken), _newFee);
    }

    /*
     * Set new fee recipient.
     *
     * @param _indexToken             Address of IndexToken
     * @param _newFeeRecipient      New fee recipient
     */
    function updateFeeRecipient(IIndexToken _indexToken, address _newFeeRecipient)
        external
        onlyIndexManager(_indexToken, msg.sender)
        onlyValidAndInitializedIndex(_indexToken)
    {
        require(_newFeeRecipient != address(0), "Fee Recipient must be non-zero address.");

        feeStates[_indexToken].feeRecipient = _newFeeRecipient;

        emit FeeRecipientUpdated(address(_indexToken), _newFeeRecipient);
    }

    /*
     * Calculates total inflation percentage in order to accrue fees to manager.
     *
     * @param _indexToken       Address of IndexToken
     * @return  uint256       Percent inflation of supply
     */
    function getFee(IIndexToken _indexToken) external view returns (uint256) {
        return _calculateStreamingFee(_indexToken);
    }

    /* ============ Internal Functions ============ */

    /**
     * Calculates streaming fee by multiplying streamingFeePercentage by the elapsed amount of time since the last fee
     * was collected divided by one year in seconds, since the fee is a yearly fee.
     *
     * @param  _indexToken          Address of Set to have feeState updated
     * @return uint256            Streaming fee denominated in percentage of totalSupply
     */
    function _calculateStreamingFee(IIndexToken _indexToken) internal view returns(uint256) {
        uint256 timeSinceLastFee = block.timestamp.sub(_lastStreamingFeeTimestamp(_indexToken));

        // Streaming fee is streaming fee times years since last fee
        return timeSinceLastFee.mul(_streamingFeePercentage(_indexToken)).div(ONE_YEAR_IN_SECONDS);
    }

    /**
     * Returns the new incentive fee denominated in the number of IndexTokens to mint. The calculation for the fee involves
     * implying mint quantity so that the feeRecipient owns the fee percentage of the entire supply of the Set.
     *
     * The formula to solve for fee is:
     * (feeQuantity / feeQuantity) + totalSupply = fee / scaleFactor
     *
     * The simplified formula utilized below is:
     * feeQuantity = fee * totalSupply / (scaleFactor - fee)
     *
     * @param   _indexToken               IndexToken instance
     * @param   _feePercentage          Fee levied to feeRecipient
     * @return  uint256                 New RebalancingSet issue quantity
     */
    function _calculateStreamingFeeInflation(
        IIndexToken _indexToken,
        uint256 _feePercentage
    )
        internal
        view
        returns (uint256)
    {
        uint256 totalSupply = _indexToken.totalSupply();

        // fee * totalSupply
        uint256 a = _feePercentage.mul(totalSupply);

        // ScaleFactor (10e18) - fee
        uint256 b = PreciseUnitMath.preciseUnit().sub(_feePercentage);

        return a.div(b);
    }

    /**
     * Mints sets to both the manager and the protocol. Protocol takes a percentage fee of the total amount of Sets
     * minted to manager.
     *
     * @param   _indexToken               IndexToken instance
     * @param   _feeQuantity            Amount of Sets to be minted as fees
     * @return  uint256                 Amount of Sets accrued to manager as fee
     * @return  uint256                 Amount of Sets accrued to protocol as fee
     */
    function _mintManagerAndProtocolFee(IIndexToken _indexToken, uint256 _feeQuantity) internal returns (uint256, uint256) {
        address protocolFeeRecipient = controller.feeRecipient();
        uint256 protocolFee = controller.getModuleFee(address(this), PROTOCOL_STREAMING_FEE_INDEX);

        uint256 protocolFeeAmount = _feeQuantity.preciseMul(protocolFee);
        uint256 managerFeeAmount = _feeQuantity.sub(protocolFeeAmount);

        _indexToken.mint(_feeRecipient(_indexToken), managerFeeAmount);

        if (protocolFeeAmount > 0) {
            _indexToken.mint(protocolFeeRecipient, protocolFeeAmount);
        }

        return (managerFeeAmount, protocolFeeAmount);
    }

    /**
     * Calculates new position multiplier according to following formula:
     *
     * newMultiplier = oldMultiplier * (1-inflationFee)
     *
     * This reduces position sizes to offset increase in supply due to fee collection.
     *
     * @param   _indexToken               IndexToken instance
     * @param   _inflationFee           Fee inflation rate
     */
    function _editPositionMultiplier(IIndexToken _indexToken, uint256 _inflationFee) internal {
        int256 currentMultipler = _indexToken.positionMultiplier();
        int256 newMultiplier = currentMultipler.preciseMul(PreciseUnitMath.preciseUnit().sub(_inflationFee).toInt256());

        _indexToken.editPositionMultiplier(newMultiplier);
    }

    function _feeRecipient(IIndexToken _set) internal view returns (address) {
        return feeStates[_set].feeRecipient;
    }

    function _lastStreamingFeeTimestamp(IIndexToken _set) internal view returns (uint256) {
        return feeStates[_set].lastStreamingFeeTimestamp;
    }

    function _maxStreamingFeePercentage(IIndexToken _set) internal view returns (uint256) {
        return feeStates[_set].maxStreamingFeePercentage;
    }

    function _streamingFeePercentage(IIndexToken _set) internal view returns (uint256) {
        return feeStates[_set].streamingFeePercentage;
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// mock class using BasicToken
contract StandardTokenMock is ERC20 {
    constructor(
        address _initialAccount,
        uint256 _initialBalance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        public
        ERC20(_name, _symbol)
    {
        _mint(_initialAccount, _initialBalance);
        _setupDecimals(_decimals);
    }

   function mint(address to, uint amount) external {
       _mint(to, amount);
   }
}