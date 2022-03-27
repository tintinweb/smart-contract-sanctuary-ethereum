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