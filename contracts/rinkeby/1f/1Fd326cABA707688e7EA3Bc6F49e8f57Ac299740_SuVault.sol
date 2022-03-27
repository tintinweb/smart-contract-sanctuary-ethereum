// SPDX-License-Identifier: UNLICENSED

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

import "./SuVaultParameters.sol";
import "./original-unit-contracts/helpers/SafeMath.sol";

contract SuUSD is Auth {
    using SafeMath for uint;

    // our name will be UNIT
    string public constant name = "USDP Stablecoin";

    // symbol UNIT
    string public constant symbol = "USDP";

    // can it be redeployed? can it be any other value?
    /// i think it useless
    string public constant version = "1";

    // always 18 decimals the same like ETH
    uint8 public constant decimals = 18;

    // how many dollars in circulation
    uint public totalSupply;

    // balance of each account
    mapping(address => uint) public balanceOf;

    // how many dollars one address is allowed to transfer from another
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor(address _parameters) Auth(_parameters) {}

    /**
      * @notice Only Vault can mint USDP
      * @dev Mints 'amount' of tokens to address 'to', and MUST fire the
      * Transfer event
      * @param to The address of the recipient
      * @param amount The amount of token to be minted
     **/

     // dollars can be minted by vault (once user deposited collateral)
    function mint(address to, uint amount) external onlyVault {
        require(to != address(0), "Unit Protocol: ZERO_ADDRESS");

        balanceOf[to] = balanceOf[to].add(amount);
        totalSupply = totalSupply.add(amount);

        emit Transfer(address(0), to, amount);
    }

    // dollars can be burned by manager but only his own dollars
    // which managers will be using this feature? burning protocol fees?
    function burn(uint amount) external onlyManager {
        _burn(msg.sender, amount);
    }

     // also vault is allowed to burn dollars of any account
     // when user repays his loan and takes back his collateral
    function burn(address from, uint amount) external onlyVault {
        _burn(from, amount);
    }

    // I think transfer and transferFrom should execute the same internal function
    // instead of transfer executing transferFrom
    function transfer(address to, uint amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    // implementation by standard - allows one user to transfer from another account
    // in which cases our contracts will utilize this ability?
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(to != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(balanceOf[from] >= amount, "Unit Protocol: INSUFFICIENT_BALANCE");

        if (from != msg.sender) {
            require(allowance[from][msg.sender] >= amount, "Unit Protocol: INSUFFICIENT_ALLOWANCE");
            _approve(from, msg.sender, allowance[from][msg.sender].sub(amount));
        }
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);

        emit Transfer(from, to, amount);
        return true;
    }

    // at which point in user experience will he send approve transaction?
    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // alternative to approve
    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    // to manage amount granuarly
    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    // in our case we inherit from OZ and these function are there
    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "Unit Protocol: approve from the zero address");
        require(spender != address(0), "Unit Protocol: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // as well this one inherited from OZ
    function _burn(address from, uint amount) internal virtual {
        balanceOf[from] = balanceOf[from].sub(amount);
        totalSupply = totalSupply.sub(amount);

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

import "./original-unit-contracts/helpers/SafeMath.sol";
import "./SuVaultParameters.sol";
import "./original-unit-contracts/helpers/TransferHelper.sol";
import "./SuUSD.sol";
import "./original-unit-contracts/interfaces/IWETH.sol";

contract SuVault is Auth {
    // don't need anymore in modern solidity?
    /// correct
    using SafeMath for uint;

    // dont need theirs token 
    /// yes
    address public immutable col;

    // only wrapped ether will be supported
    /// yes
    address payable public immutable weth;

    // 10^5 = 100000
    uint public constant DENOMINATOR_1E5 = 1e5;

    // 10^2 = 100
    uint public constant DENOMINATOR_1E2 = 1e2;

    // token itself - will be unit stable coin
    address public immutable usdp;

    // which tokens are allowed as collateral; what's the int value - min threshold or rate?
    /// No, it's how much user had stacked collaterael asset == collaterals[asset][user], i.e deposits
    mapping(address => mapping(address => uint)) public collaterals;

    // the same but for theirs token - can be ignored
    mapping(address => mapping(address => uint)) public colToken;

    // mapping of user address to integer value; which is the amount of debt represented by what?
    /// Yes, in stablecoin amount, == debts[asset][user]
    // or might be it mapping fro token address into total debt amount?
    mapping(address => mapping(address => uint)) public debts;

    // liquidation can be triggered by permissionless-action?
    /// Yes
    // then the process begins and we remember which block it started at
    // is it indexed by collateral token address?
    /// Yes ,  liquidationBlock[asset][user]
    mapping(address => mapping(address => uint)) public liquidationBlock;

    // mapping of collateral address to liquidation price;
    // when and who decides on the collateral price, is that dynamic?
    /// see line 287 triggerLiquidation: liquidationPrice[asset][positionOwner] = initialPrice;
    mapping(address => mapping(address => uint)) public liquidationPrice;

    // mapping of address to integer for token debts;
    // what'is the units of measurement?
    /// How much stablecoin was borrowed against particular asset == tokenDebts[asset]  
    mapping(address => uint) public tokenDebts;

    // double mapping probably from collateral to each user to debt
    // how is stability fee calculated and where is it paid and when?
    /// current interest that user pay for stabilityFee[asset][user]
    mapping(address => mapping(address => uint)) public stabilityFee;

    // another similar mapping for another fee, how is liquidation fee different from stability fee?
    // can we combine both mapping into single mapping to structure?
    /// Penalty during liquidation
    mapping(address => mapping(address => uint)) public liquidationFee;

    // mapping for oracles; are there different oracle types? who is allowed to choose oracle?
    // oracles are passive
    /// ID of oracle contact for oracleType[asset][user]
    mapping(address => mapping(address => uint)) public oracleType;

    // mapping for timestamps;
    // why do we need timestamps? how do we calculate medium price when merging positions?
    /// everything before lastUpdates is already calced in the debt. all data such as fees are from lastUpdate only
    mapping(address => mapping(address => uint)) public lastUpdate;

    // check if liquidation process not started for asset of user
    /// YES
    modifier notLiquidating(address asset, address user) {
        require(liquidationBlock[asset][user] == 0, "Unit Protocol: LIQUIDATING_POSITION");
        _;
    }

    // vault is initialize with parameters for auth (we are using OZ instead)
    // and it accept address for wrapped eth, main stable coin, and probably governance token
    /// YES
    constructor(address _parameters, address _col, address _usdp, address payable _weth) Auth(_parameters) {
        col = _col;
        usdp = _usdp;
        weth = _weth;
    }

    // do not accept direct payments from users because they will be stuck on contract address
    /// YES, does work for erc20
    receive() external payable {
        require(msg.sender == weth, "Unit Protocol: RESTRICTED");
    }

     // who does have vault access?
     /// anyone from canModifyVault
     // why position is not allowed to be modified during liquidation?
     /// because when it's launched - liquidators want to be sure they can participate
     // how often update can be triggered?
     /// when user borrows more 
    function update(address asset, address user) public hasVaultAccess notLiquidating(asset, user) {
        
        // probably should be checked if zero then skip
        /// 
        uint debtWithFee = getTotalDebt(asset, user);

        // we decrease token debt by current debt and increase by new debt
        // can we just set new value instead?
        tokenDebts[asset] = tokenDebts[asset].sub(debts[asset][user]).add(debtWithFee);
        
        // we set new debt for asset of user
        debts[asset][user] = debtWithFee;

        // we also set new fee
        stabilityFee[asset][user] = vaultParameters.stabilityFee(asset);
        
        // we also set new fee
        liquidationFee[asset][user] = vaultParameters.liquidationFee(asset);
        
        // and update timestamp
        lastUpdate[asset][user] = block.timestamp;
    }

     // spawn means to create new debt position for user
     // it accepts collateral token address and user and chosen oracle type
     // this function is not called by user but by special priviliged account?
     /// yes, by CDP manager 01
     // what are the options for oracle type?
     /// all implementation are numbered
    function spawn(address asset, address user) external hasVaultAccess notLiquidating(asset, user) {
        
        // why its being removed and which cases its not empty?
        /// could be liquidationBlock[asset][user] = 0;
        delete liquidationBlock[asset][user];
    }

    // does it help to restore gas fees? what's the purpose of cleanup?
    /// Not clear for after London hardfork
    // how do ensure its not being called unexpectedly? very dangerous function 
    /// only destroy debt info, exit -> _repay -> destroy if debt == 0
    function destroy(address asset, address user) public hasVaultAccess notLiquidating(asset, user) {
        delete stabilityFee[asset][user];
        delete oracleType[asset][user];
        delete lastUpdate[asset][user];
        delete liquidationFee[asset][user];
    }

     // collateral deposit
    function depositMain(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        collaterals[asset][user] = collaterals[asset][user].add(amount);
        TransferHelper.safeTransferFrom(asset, user, address(this), amount);
    }

    // wrapped ether deposit
    // can be called by anyone? how do we reject weth transfers by mistake?
    function depositEth(address user) external payable notLiquidating(weth, user) {
        IWETH(weth).deposit{value: msg.value}();
        collaterals[weth][user] = collaterals[weth][user].add(msg.value);
    }

     // collateral withdraw
     // why being called by privileged account and not by user?
    function withdrawMain(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        collaterals[asset][user] = collaterals[asset][user].sub(amount);
        TransferHelper.safeTransfer(asset, user, amount);
    }

    // withdraw wrapper ether
    function withdrawEth(address payable user, uint amount) external hasVaultAccess notLiquidating(weth, user) {
        collaterals[weth][user] = collaterals[weth][user].sub(amount);
        IWETH(weth).withdraw(amount);
        TransferHelper.safeTransferETH(user, amount);
    }

    // this can be ignored
    function depositCol(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        colToken[asset][user] = colToken[asset][user].add(amount);
        TransferHelper.safeTransferFrom(col, user, address(this), amount);
    }

    // this can be ignored
    function withdrawCol(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        colToken[asset][user] = colToken[asset][user].sub(amount);
        TransferHelper.safeTransfer(col, user, amount);
    }

     // BORROW == takeUnit
     /// yes, fro cdpManager01
     // user expected previously to deposit collateral and then being able to take stablecoin
     // but where do we check current user collateral and amount??
     /// in CDPManager01
     // can user create single position with multiple collaterals?
     /// no, one debt for [asset][user]
    function borrow(
        address asset,
        address user,
        uint amount
    )
    external
    hasVaultAccess
    notLiquidating(asset, user)
    returns(uint)
    {
        // update debts and fees of user for collateral
        /// I think better name is needed
        update(asset, user);

        // why we update it again after update already called?
        /// becaause update doesn't use amount, only calc curr fees
        debts[asset][user] = debts[asset][user].add(amount);
        tokenDebts[asset] = tokenDebts[asset].add(amount);

        // there is a limit of total debt for each collateral
        // why that limit is needed?
        /// because of risk profile
        require(tokenDebts[asset] <= vaultParameters.tokenDebtLimit(asset), "Unit Protocol: ASSET_DEBT_LIMIT");

        // here stablecoin is created for user
        SuUSD(usdp).mint(user, amount);

        // we return value of previous debt plus new debt
        // how this can be accessed and used by client?
        // should consider to emit events instead
        return debts[asset][user];
    }

    // REPAY == giveUnit
    /// return for the debt
    function repay(
        address asset,
        address user,
        uint amount
    )
    external
    hasVaultAccess
    notLiquidating(asset, user)
    returns(uint)
    {
        // current debt of user by given collateral
        uint debt = debts[asset][user];
        
        // is being decreased by chosen amount
        debts[asset][user] = debt.sub(amount);

        // total debt by asset is being decreased too
        // this value is used to limit total collateral allowed debt
        tokenDebts[asset] = tokenDebts[asset].sub(amount);

        // we burn stablecoin from user
        // vault should have corresponding permission
        SuUSD(usdp).burn(user, amount);

        // after we burn stablecoin we need to take back collateral
        // does that happen in another contract which calls this function?

        return debts[asset][user];
    }

    // transfering chosen amount chosen asset from user to foundation address
    // can foundation address be changed?
    /// Yes, setFoundation.
    // why its being transferred from user? instead should be from this vault
    /// TODO: he doesn't have his vault with usdp
    // why amount is chosen manually? should be always the same value as in fees mapping
    /// this is just tranfer function, manager calc fees
    function chargeFee(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        if (amount != 0) {
            TransferHelper.safeTransferFrom(asset, user, vaultParameters.foundation(), amount);
        }
    }

    // position liquidation being triggerred by another contract
    // initial price is passed here but better it would be accessed from mapping directly
    /// it's Vault so Manager does tells it what to do.
    function triggerLiquidation(
        address asset,
        address positionOwner,
        uint initialPrice
    )
    external
    hasVaultAccess
    notLiquidating(asset, positionOwner)
    {
        // why debt recalculation is needed and which cases it can be outdated?
        /// because function called from CDPManger01.triggerLiquidation which doesn't call update
        debts[asset][positionOwner] = getTotalDebt(asset, positionOwner);

        // remember when liquidation start and which price
        liquidationBlock[asset][positionOwner] = block.number;
        liquidationPrice[asset][positionOwner] = initialPrice;
    }




     // liquidation can happen after liquidator is chosen through auction
     // and auction starts after liquidation starting process has triggered
     /// YES
     // liquidator accepts a deal to give minimum amount of stablecoin and receive all position collateral
     /// NO, 
     // mainAsset is collateral
     /// YES
     // why col is needed? can be ignored
     /// CORRECT
     // what is repayment and what is penalty?
     /// 
     // what happens if liquidator does not execute agreed transaction?
     /// 
     // borrower should receive some part of stablecoin given by liquidator
     /// POSSIBLY
     // how is that portion calculated and where the rest goes?
     /// YES, please see _liquidate at LiquidationAunction02
     // will stablecoin paid by liquidator be burned immediately?
     /// Yes
     // how can cascading liquidation happen step by step?
     /// please see https://ratiofinance.medium.com/ratio-risk-lesson-2-cascading-liquidations-e91e04050f47
    function liquidate(
        address asset,
        address positionOwner,
        uint mainAssetToLiquidator,
        uint colToLiquidator,
        uint mainAssetToPositionOwner,
        uint colToPositionOwner,
        uint repayment,
        uint penalty,
        address liquidator
    )
        external
        hasVaultAccess
    {
        require(liquidationBlock[asset][positionOwner] != 0, "Unit Protocol: NOT_TRIGGERED_LIQUIDATION");

        uint mainAssetInPosition = collaterals[asset][positionOwner];

        uint mainAssetToFoundation = mainAssetInPosition.sub(mainAssetToLiquidator).sub(mainAssetToPositionOwner);

        uint colInPosition = colToken[asset][positionOwner];
        uint colToFoundation = colInPosition.sub(colToLiquidator).sub(colToPositionOwner);

        delete liquidationPrice[asset][positionOwner];
        delete liquidationBlock[asset][positionOwner];
        delete debts[asset][positionOwner];
        delete collaterals[asset][positionOwner];
        delete colToken[asset][positionOwner];

        destroy(asset, positionOwner);

        if (repayment > penalty) {
            if (penalty != 0) {
                TransferHelper.safeTransferFrom(usdp, liquidator, vaultParameters.foundation(), penalty);
            }
            SuUSD(usdp).burn(liquidator, repayment.sub(penalty));
        } else {
            if (repayment != 0) {
                TransferHelper.safeTransferFrom(usdp, liquidator, vaultParameters.foundation(), repayment);
            }
        }

        if (mainAssetToLiquidator != 0) {
            TransferHelper.safeTransfer(asset, liquidator, mainAssetToLiquidator);
        }

        if (colToLiquidator != 0) {
            TransferHelper.safeTransfer(col, liquidator, colToLiquidator);
        }

        if (mainAssetToPositionOwner != 0) {
            TransferHelper.safeTransfer(asset, positionOwner, mainAssetToPositionOwner);
        }

        if (colToPositionOwner != 0) {
            TransferHelper.safeTransfer(col, positionOwner, colToPositionOwner);
        }

        if (mainAssetToFoundation != 0) {
            TransferHelper.safeTransfer(asset, vaultParameters.foundation(), mainAssetToFoundation);
        }

        if (colToFoundation != 0) {
            TransferHelper.safeTransfer(col, vaultParameters.foundation(), colToFoundation);
        }
    }

    // oracle type can be changed manager, under which conditions?
    /// any time
    function changeOracleType(address asset, address user, uint newOracleType) external onlyManager {
        oracleType[asset][user] = newOracleType;
    }

    // total dept is calculated as current debt with added calculated fee
    /// they don't use it in practice
    function getTotalDebt(address asset, address user) public view returns (uint) {
        uint debt = debts[asset][user];
        if (liquidationBlock[asset][user] != 0) return debt;
        uint fee = calculateFee(asset, user, debt);
        return debt.add(fee);
    }

     // fee is increased with time and 
     /// YES
     // decreased when partial repayment is made 
     /// No, any call of valult.update would calc fee in debt and restart fee timer
    function calculateFee(address asset, address user, uint amount) public view returns (uint) {
        uint sFeePercent = stabilityFee[asset][user];
        uint timePast = block.timestamp.sub(lastUpdate[asset][user]);

        return amount.mul(sFeePercent).mul(timePast).div(365 days).div(DENOMINATOR_1E5);
    }
}

// SPDX-License-Identifier: UNLICENSED

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;


// proxy for VaultParameters - other contracts should be inherited from here
// this contract contains modifiers used in VaultParameters contract
// it should be an abstract class because it cannot by instantiated/deployed directly,
// its supposed to be inherited by VaultParameters contract which is deployed 
/// yes
contract Auth {
    // but actually it does store address to vaultParameters contract?
    SuVaultParameters public vaultParameters;

    // its the same time parent of VaultParameters (inheritance)
    // and same time its linking to VaultParameters (composition)
    // one approach should be chosen: either inheritance or composition
    // otherwise its very confusing
    /// No, it's singleton
    constructor(address _parameters) {
        vaultParameters = SuVaultParameters(_parameters);
    }

    // check manager permission
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: onlyManager AUTH_FAILED");
        _;
    }

    // check permission to modify vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: hasVaultAccess AUTH_FAILED");
        _;
    }

    // check vault permission
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: onlyVault AUTH_FAILED");
        _;
    }
}


// VaultParameters is Singleton for Access Control
// this looks like configuration contract
// what are the rules to determine these configs for each new allowed collateral?
/// yes, and for all collaterals
// is DAO allowed to choose parameters for existing collaterals?
/// 
// are there any limits to be enforced? i.e. fee cannot be over 100% percent
/// No, but it's a good idea to have it
contract SuVaultParameters is Auth {
    // stability fee can be different for each collateral
    /// yes
    mapping(address => uint) public stabilityFee;

    // liquidation fee too can be different
    /// yes
    mapping(address => uint) public liquidationFee;

    // map token to USDP mint limit
    /// yes, limit for each collateral-assert
    mapping(address => uint) public tokenDebtLimit;

    // permissions to modify the Vault
    mapping(address => bool) public canModifyVault;

    // whether an account is manager
    mapping(address => bool) public isManager;

    // whether an oracle is enabled
    /// TODO:
    mapping(uint => mapping (address => bool)) public isOracleTypeEnabled;

    // linked to the vault contract
    // I think its better to inherit Vault from VaultParameters
    /// NO, needed for onlyVault modifier
    address payable public vault;

    // what is foundation, DAO?
    /// Beneficiaty as VotingEscrow.vy
    address public foundation;

    // creator of contract is manager, can it be the same as DAO or can it be removed later?
    /// YES
    // how can vault address be known at this moment?
    /// Precult based on CREATE spec
    // can be created another function to set vault address once deployed?
    /// Yes, possibly with some logic change
    constructor(address payable _vault, address _foundation) Auth(address(this)) {
        require(_vault != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(_foundation != address(0), "Unit Protocol: ZERO_ADDRESS");

        isManager[msg.sender] = true;
        vault = _vault;
        foundation = _foundation;
    }

     // existing managers can enable other managers
     // one manager can disable all other managers - dangerous?
     /// YES, could be dangerous
    function setManager(address who, bool permit) external onlyManager {
        isManager[who] = permit;
    }

    // similar function can be added to setVault
    function setFoundation(address newFoundation) external onlyManager {
        require(newFoundation != address(0), "Unit Protocol: ZERO_ADDRESS");
        foundation = newFoundation;
    }

     // manager is allowed to add new collaterals and modify existing ones
     // I think creating new collaterals and modifying existing ones should be separate functions
     /// Yes, for sercurity reason, it's possible to add events for creating and edititing 
     // also different event should be emitted NewCollateral UpdatedCollateral accordingly
     // those events can be handled on frontend to notify user about any changes in rules
     /// Not sure it makes sense to split into create/edit functions
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint usdpLimit
    ) external onlyManager {
        // stability fee should be validated in range, what is stability fee should be described here?
        setStabilityFee(asset, stabilityFeeValue);
        // liquidation fee should be validated in range, what is liquidation fee should be explained?
        setLiquidationFee(asset, liquidationFeeValue);
        // why debt limit for collateral is necessary? to manage risks in case of collateral failure?
        setTokenDebtLimit(asset, usdpLimit);
    }

     // manager can choose who is allowed to modify vault, 
     // what does it mean to modify vault and why permission separate from manager himself?
     /// https://en.wikipedia.org/wiki/Principle_of_least_privilege 
    function setVaultAccess(address who, bool permit) external onlyManager {
        canModifyVault[who] = permit;
    }

    // stability fee is measured as the number of coins per year or percentage? 
    // this should be clarified in argument name i.e. stabilityFeePercentageYearly
    /// No, it's APR ( per year, see calculateFee) percentrage, fee percentage; 3 decimals.
    /// YES, self-documented code-style is the best practice.
    function setStabilityFee(address asset, uint newValue) public onlyManager {
        stabilityFee[asset] = newValue;
    }

    // the same with liquidation fee is not clear
    /// % 0 decimals, needede to get better variable names
    function setLiquidationFee(address asset, uint newValue) public onlyManager {
        require(newValue <= 100, "Unit Protocol: VALUE_OUT_OF_RANGE");
        liquidationFee[asset] = newValue;
    }

     // what are allowed types? enum should be defined
     // types out of range should fail transaction
    /// All oracles implementation are numbered, so some of them support this particular asset
    function setOracleType(uint _type, address asset, bool enabled) public onlyManager {
        isOracleTypeEnabled[_type][asset] = enabled;
    }

     // debt limit can be changed for any collateral along with liquidation and stability fees
     // seems like managers have too much power - that can be dangerous given multiple managers?
     /// Yes, application of  principle of least priviledge needed
    function setTokenDebtLimit(address asset, uint limit) public onlyManager {
        tokenDebtLimit[asset] = limit;
    }
}

// SPDX-License-Identifier: UNLICENSED

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

// library to extend contracts with helper methods
// which are the contracts where its being used?
library TransferHelper {
    // internal function to approve
    function safeApprove(address token, address to, uint value) internal {
        // function signature should be inline variable instead 
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        
        // what is difference between success=false OR data.length = 0 OR data encoded ?
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    // internal function to transfer
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    // internal function to transfer from
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    // internal function to transfer eth
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: UNLICENSED

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}