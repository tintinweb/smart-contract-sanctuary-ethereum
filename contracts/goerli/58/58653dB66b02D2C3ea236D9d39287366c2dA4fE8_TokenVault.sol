// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

///////////////////////////////////////////////////////////
// IMPORTS
//
// This enables the author of the contract to own it, and provide
// ownership only methods to be called by the author for maintenance
// or other issues.
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Initializable interface is required because constructors don't work the same
// way for upgradeable contracts.
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// We are using the UUPSUpgradeable Proxy pattern instead of the transparent proxy
// pattern because its more gas efficient and comes with some better trade-offs.
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Be able to produce the ethereum arn
import "../../libraries/AssetResourceName.sol";
using AssetResourceName for AssetResourceName.AssetType;

// We want to track contract addresses
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
using EnumerableSet for EnumerableSet.AddressSet;

// We want to use the ERC20 interface so each trust can hold any arbitrary
// ERC20. This enables the trusts to hold all sorts of assets, not just ethereum.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Platform interfaces
import "../interfaces/IKeyVault.sol";
import "../interfaces/ILocksmith.sol";
import "../interfaces/ILedger.sol";
import "../interfaces/ITokenCollateralProvider.sol";
///////////////////////////////////////////////////////////

/**
 * TokenVault 
 *
 * A simple implementation of an ERC20 token vault that acts as 
 * a trusted collateral provider to the ledger.
 *
 * A root key holder can deposit their funds, and entrust the
 * ledger to maintain withdrawal-rights to the vault.
 *
 * It takes the same dependency as the ledger does - the Locksmith, and uses the 
 * ERC1155 keys minted from that contract for access control.
 *
 * TokenVault requires to act as Collateral Provider to the Ledger, and relies on it
 * to deposit key holder allocation entries or verify a key balance for withdrawal.
 *
 * In the end, this contract holds the tokens and abstracts out the ARN 
 * into the ERC20 protocol implementation.
 */
contract TokenVault is ITokenCollateralProvider, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    ///////////////////////////////////////////////////////
    // Storage
    ///////////////////////////////////////////////////////
    // Locksmith verifies key-holdership. 
    ILocksmith public locksmith;
    
    // The Locksmith provides access to mutate the ledger.
    ILedger public ledger;

    // witnessed token addresses
    // trust => [registered addresses] 
    mapping(uint256 => EnumerableSet.AddressSet) private witnessedTokenAddresses;
    mapping(bytes32 => address) public arnContracts;

    // we need to keep track of the deposit balances safely
    mapping(address => uint256) tokenBalances;

    ///////////////////////////////////////////////////////
    // Constructor and Upgrade Methods
    //
    // This section is specifically for upgrades and inherited
    // override functionality.
    ///////////////////////////////////////////////////////
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // this disables all previous initializers
        _disableInitializers();
    }

    /**
     * initialize()
     *
     * Fundamentally replaces the constructor for an upgradeable contract.
     * This contract relies on the ERC1155 contract for the Trust Key manager.
     * 
     * @param _Locksmith the address of the proxy for the locksmith
     * @param _Ledger    the address of the proxy for the ledger
     */
    function initialize(address _Locksmith, address _Ledger) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        // this implies a specific deployment order that trust key
        // must be mined first.
        locksmith = ILocksmith(_Locksmith);
        ledger = ILedger(_Ledger);
    }

    /**
     * _authorizeUpgrade
     *
     * This method is required to safeguard from un-authorized upgrades, since
     * in the UUPS model the upgrade occures from this contract, and not the proxy.
     * I think it works by reverting if upgrade() is called from someone other than
     * the owner.
     *
     * // UNUSED: -param newImplementation the new address implementation to upgrade to
     */
    function _authorizeUpgrade(address) internal view onlyOwner override { }

    ////////////////////////////////////////////////////////
    // External Methods
    //
    // These methods should be considered as the public interface
    // of the contract. They are for interaction with by wallets,
    // web frontends, and tests.
    ////////////////////////////////////////////////////////

    /**
     * getTrustedLedger
     *
     * @return address reference that the vault uses to trust for key permissions.
     */
    function getTrustedLedger() external view returns (address) {
        return address(ledger);
    }

    /**
     * deposit
     *
     * This method will enable root key holders to deposit ERC20s into
     * the trust. This method operates under the assumption of approval. 
     *
     * @param keyId the ID of the key that the depositor is using.
     * @param token the address of the ERC20 token contract.
     * @param amount the amount to deposit
     */
    function deposit(uint256 keyId, address token, uint256 amount) external {
        // stop right now if the message sender doesn't hold the key
        require(IKeyVault(locksmith.getKeyVault()).keyBalanceOf(msg.sender, keyId, false) > 0, 'KEY_NOT_HELD');

        // generate the token arn
        bytes32 tokenArn = AssetResourceName.AssetType({
            contractAddress: token, 
            tokenStandard: 20, 
            id: 0 
        }).arn();

        // store the contract address to enable withdrawals
        arnContracts[tokenArn] = token;

        // make sure the caller has a sufficient token balance.
        require(IERC20(token).balanceOf(msg.sender) >= amount,
            "INSUFFICIENT_TOKENS");
        
        // transfer tokens in the target token contract. if the
        // control flow ever got back into the callers hands
        // before modifying the ledger we could end up re-entrant.
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // track the deposit on the ledger
        // this could revert for a few reasons:
        // - the key is not root
        // - the vault is not a trusted collateral provider the ledger
        (,,uint256 finalLedgerBalance) = ledger.deposit(keyId, tokenArn, amount);

        // increment the witnessed token balance
        tokenBalances[token] += amount;

        // jam the vault if the ledger's balance 
        // provisions doesn't match the vault balance
        assert(finalLedgerBalance == tokenBalances[token]);

        // update the witnessed token addresses, so we can easily describe
        // the trust-level tokens in this vault.
        (,,uint256 trustId,,) = locksmith.inspectKey(keyId);
        witnessedTokenAddresses[trustId].add(token);
    }

    /**
     * withdrawal
     *
     * Given a key, attempt to withdrawal ERC20 from the vault. This will only
     * succeed if the key is held by the user, the key has the permission to
     * withdrawal, the rules of the trust are satisified (whatever those may be),
     * and there is sufficient balance. If any of those fail, the entire
     * transaction will revert and fail.
     *
     * @param keyId  the key you want to use to withdrawal with/from
     * @param token  the token contract representing the ERC20
     * @param amount the amount of ether, in gwei, to withdrawal from the balance.
     */
    function withdrawal(uint256 keyId, address token, uint256 amount) external {
        // generate the ARN, and then withdrawal
        _withdrawal(keyId, AssetResourceName.AssetType({
            contractAddress: token, 
            tokenStandard: 20, 
            id: 0 
        }).arn(), token, amount);
    }
    
    /**
     * arnWithdrawal
     *
     * Functions exactly like #withdrawal, but takes an ARN and does
     * the internal conversion to contract address. This vault will fail
     * the withdrawal if it was never deposited as it wont recognize the arn.
     *
     * @param keyId  the key you want to use to withdrawal with/from
     * @param arn    the asset resource name to withdrawal 
     * @param amount the amount of ether, in gwei, to withdrawal from the balance.
     */
    function arnWithdrawal(uint256 keyId, bytes32 arn, uint256 amount) external {
        // grab the address for the contract. If this ends up being address(0), the
        // ledger should fail to withdrawal, so there is no need to check it here
        _withdrawal(keyId, arn, arnContracts[arn], amount); 
    }

    /**
     * getTokenTypes
     *
     * Given a specific key, will return the contract addresses for all
     * ERC20s held in the vault. 
     *
     * @param keyId the key you are using to access the trust
     * @return the token registry for that trust
     */
    function getTokenTypes(uint256 keyId) external view returns(address[] memory) {
        // I really should be taking the arns from the ledger and recoding
        // it to get the contract addresses, but for 20-30 arns thats going
        // to be an expensive call.
        (,,uint256 trustId,,) = locksmith.inspectKey(keyId);
        return witnessedTokenAddresses[trustId].values();
    }

    ////////////////////////////////////////////////////////
    // Internal Methods
    ////////////////////////////////////////////////////////

    /**
     * _withdrawal
     *
     * Internal method that takes both the arn and the token address to
     * perform the common actions that are required for each withdrawal
     * scenario.
     *
     * @param keyId  the key to withdrawal from the ledger
     * @param arn    the asset idenitifier to withdrawal from the ledger
     * @param token  the token address to use to move assets.
     * @param amount the amount of assets to remove from the ledger, and send.
     */
    function _withdrawal(uint256 keyId, bytes32 arn, address token, uint256 amount) internal {
        // stop right now if the message sender doesn't hold the key
        require(IKeyVault(locksmith.getKeyVault()).keyBalanceOf(msg.sender, keyId, false) > 0, 'KEY_NOT_HELD');

        // withdrawal from the ledger *first*. if there is an overdraft,
        // the entire transaction will revert.
        (,, uint256 finalLedgerBalance) = ledger.withdrawal(keyId, arn, amount);

        // decrement the witnessed token balance
        tokenBalances[token] -= amount;

        // jam the vault if the ledger's balance doesn't
        // match the vault balance after withdrawal
        assert(tokenBalances[token] == finalLedgerBalance);
        
        // We trust that the ledger didn't overdraft so
        // send at the end to prevent re-entrancy.
        IERC20(token).transfer(msg.sender, amount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * AssetResourceName
 *
 * This library and set of functions help portions of the trust
 * contracts act as asset agnostic as they can. To do so, they need
 * a robust data model for differentiating, identifying, and
 * introspecting on assets of different types.
 *
 * This library was generally conceived to cover gas tokens (eth),
 * fungible tokens of varying types (ERC20, ERC777), and non-fungible
 * token types (721, 1155), but could be escape hatched to support
 * other unknown standards at a later time.
 */
library AssetResourceName {
    struct AssetType {
        // all EVM tokens originate from a contract
        address contractAddress;

        // identifies the token standard for this asset
        // '0' is considered the native gas token,
        // or is otherwise considered 20, 721, 777, 1155, etc.
        uint256 tokenStandard;

        // for token types that have a non-fungible ID, this
        // field is used to denote that type of asset.
        uint256 id;
    }

    // Zero is reserved for the native gas token type.
    address constant public GAS_TOKEN_CONTRACT = address(0);
    uint256 constant public GAS_TOKEN_STANDARD = 0; 
    uint256 constant public GAS_ID = 0;

    ///////////////////////////////////////////////////////
    // ARN Interface
    //
    // Importing this library and doing using / for will
    // enable these methods on the AssetType struct.
    ///////////////////////////////////////////////////////
    
    /**
     * arn
     *
     * Returns a UUID, or "asset resource name" for the asset type.
     * It is essentially the keccak256 of the asset type struct.
     * This is super convienent for mappings.
     *
     * @param asset the asset you want the arn/UUID for.
     * @return an opaque but unique identifer for this asset type.
     */
    function arn(AssetType memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(asset.contractAddress, asset.tokenStandard, asset.id)); 
    }
    
    /**
     * isAsset
     *
     * Method to determine if two assets are considered the same.
     *
     * @param a1 the baseline asset you want to compare
     * @param a2 the comparative asset you want to compare
     * @return true if they are the same, false otherwise
     */
    function isAsset(AssetType memory a1, AssetType memory a2) internal pure returns (bool) {
        return arn(a1) == arn(a2); 
    }
    
    /**
     * isConsideredGas
     *
     * This method embodies the definition of what is
     * considered a gas token, or the native asset for the
     * block chain. In basically every case, this is ethereum.
     *
     * @param asset the asset you want to determine if it's gas
     * @return true if it's gas, false otherwise
     */
    function isConsideredGas(AssetType memory asset) internal pure returns (bool) {
        return asset.tokenStandard == GAS_TOKEN_STANDARD &&
            asset.contractAddress == GAS_TOKEN_CONTRACT &&
            asset.id == GAS_ID; 
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

///////////////////////////////////////////////////////////
// IMPORTS
//
///////////////////////////////////////////////////////////

/**
 * IKeyVault 
 *
 * This simple contract is where the ERC1155s are minted and burned.
 * It has no knowledge of the rest of the system, and is used to
 * contain the tokenziation of the keys only.
 *
 * Only the contract deployer and any associated minters (locksmith's)
 * can manage the keys.
 *
 * You can use this interface to build a key vault, or connect
 * to another one that is already deployed.
 */
interface IKeyVault {
    ///////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////
    
    /**
     * setSoulboundKeyAmount 
     *
     * This event fires when the state of a soulbind key is set.
     *
     * @param operator  the person making the change, should be the locksmith
     * @param keyHolder the 'soul' we are changing the binding for
     * @param keyId     the Id we are setting the binding state for
     * @param amount    the number of tokens this person must hold
     */
    event setSoulboundKeyAmount(address operator, address keyHolder, 
        uint256 keyId, uint256 amount); 

    ////////////////////////////////////////////////////////
    // Introspection
    ////////////////////////////////////////////////////////
  
    /**
     * locksmith
     *
     * The key vault will only respect a single locksmith.
     *
     * @return the address of the Locksmith the vault respects.
     */
    function locksmith() external view returns(address);

    /**
     * getKeys
     *
     * This method will return the IDs of the keys held
     * by the given address.
     *
     * @param holder the address of the key holder you want to see
     * @return an array of key IDs held by the user.
     */
    function getKeys(address holder) external view returns (uint256[] memory); 

    /**
     * getHolders
     *
     * This method will return the addresses that hold
     * a particular keyId
     *
     * @param keyId the key ID to look for
     * @return an array of addresses that hold that key
     */
    function getHolders(uint256 keyId) external view returns (address[] memory); 
    
    /**
     * keyBalanceOf 
     *
     * We want to expose a generic ERC1155 interface here, but we are
     * going to layer it through a key vault interface..
     *
     * @param account   the wallet address you want the balance for
     * @param id        the key Id you want the balance of.
     * @param soulbound true if you want the soulbound balance
     * @return the token balance for that wallet and key id
     */
    function keyBalanceOf(address account, uint256 id, bool soulbound) external view returns (uint256);

    ////////////////////////////////////////////////////////
    // Locksmith methods 
    //
    // Only the anointed locksmith can call these. 
    ////////////////////////////////////////////////////////
    
    /**
     * mint 
     *
     * Only the locksmith can mint keys. 
     *
     * @param receiver   the address to send the new key to 
     * @param keyId      the ERC1155 NFT ID you want to mint 
     * @param amount     the number of keys you want to mint to the receiver
     * @param data       the data field for the key 
     */
    function mint(address receiver, uint256 keyId, uint256 amount, bytes calldata data) external;

    /**
     * soulbind
     *
     * The locksmith can call this method to ensure that the current
     * key-holder of a specific address cannot exchange or move a certain
     * amount of keys from their wallets. Essentially it will prevent
     * transfers.
     *
     * In the average case, this is on behalf of the root key holder of
     * a trust. 
     *
     * It is safest to soulbind in the same transaction as the minting.
     * This function does not check if the keyholder holds the amount of
     * tokens. And this function is SETTING the soulbound amount. It is
     * not additive.
     *
     * @param keyHolder the current key-holder
     * @param keyId     the key id to bind to the keyHolder
     * @param amount    it could be multiple depending on the use case
     */
    function soulbind(address keyHolder, uint256 keyId, uint256 amount) external; 

    /**
     * burn 
     *
     * We want to provide some extra functionality to allow the Locksmith
     * to burn Trust Keys on behalf of the root key holder. While the KeyVault
     * "trusts" the locksmith, the locksmith will only call this method on behalf
     * of the root key holder.
     *
     * @param holder     the address of the key holder you want to burn from
     * @param keyId      the ERC1155 NFT ID you want to burn
     * @param burnAmount the number of said keys you want to burn from the holder's possession.
     */
    function burn(address holder, uint256 keyId, uint256 burnAmount) external;    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// We are extending the interface for ERC-20 tokens 
import './ICollateralProvider.sol';

/**
 * ITokenCollateralProvider
 *
 * Interface that enables users to deposit and withdrawal
 * ERC20 funds from their trust.
 */ 
interface ITokenCollateralProvider is ICollateralProvider {
    /**
     * deposit
     *
     * This method will enable root key holders to deposit eth into
     * the trust. This method operates as a payable
     * transaction where the message's value parameter is what is deposited.
     *
     * @param keyId the ID of the key that the depositor is using.
     * @param token the address of the ERC20 token contract.
     * @param amount the amount to deposit
     */
    function deposit(uint256 keyId, address token, uint256 amount) external;

    /**
     * withdrawal
     *
     * Given a key, attempt to withdrawal ether from the vault. This will only
     * succeed if the key is held by the user, the key has the permission to
     * withdrawal, the rules of the trust are satisified (whatever those may be),
     * and there is sufficient balance. If any of those fail, the entire
     * transaction will revert and fail.
     *
     * @param keyId  the key you want to use to withdrawal with/from
     * @param token  the token contract representing the ERC20
     * @param amount the amount of ether, in gwei, to withdrawal from the balance.
     */
    function withdrawal(uint256 keyId, address token, uint256 amount) external;
    
    /**
     * getTokenTypes
     *
     * Given a specific key, will return the contract addresses for all
     * ERC20s held in the vault. 
     *
     * @param keyId the key you are using to access the trust
     * @return the token registry for that trust
     */
    function getTokenTypes(uint256 keyId) external view returns(address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

///////////////////////////////////////////////////////////
// IMPORTS
///////////////////////////////////////////////////////////

/**
 * Ledger 
 *
 * The ledger keeps track of all the balance rights of the assets
 * provided as collateral across every trust. The withdrawal rights 
 * are assigned to individual keys, on a per-asset basis. To this
 * extent, the ledger itself is asset agnostic. This provides
 * powerful flexibility on the entitlement layer to move funds easily,
 * quickly, and without multiple transactions or gas.
 *
 * Conceptually, any balances associated with a Trust's root key
 * should be considered the trust's balance itself. Once the asset
 * rights have been moved to another key, they are considered outside
 * of the trust, even if they are still on the ledger.
 *
 * This contract is designed to only be called by trusted peers. 
 * Some level of public state reflection is available, any state 
 * mutation functions require a trusted contract relationship.
 *
 * All trusted relationships are managed through the ledger's
 * associated Notary, and are anointed by a root key holder.
 */
interface ILedger {
    ////////////////////////////////////////////////////////
    // Events
    //
    // This is going to help indexers and web applications
    // watch and respond to blocks that contain trust transactions.
    ////////////////////////////////////////////////////////
    
    /**
     * depositOccurred 
     *
     * This event fires when new assets enter a vault from
     * the outside world.
     *
     * @param provider      address of the collateral provider that deposited the asset
     * @param trustId       ID of the trust that has approved the collateral provider 
     * @param keyId         keyId associated with the deposit, most often a root key
     * @param arn           asset resource name hash of the asset deposited
     * @param amount        amount of asset that was deposited
     * @param keyBalance    provider's total arn balance for that key
     * @param trustBalance  provider's total arn balance for that trust
     * @param ledgerBalance provider's total arn balance for the ledger
     */
    event depositOccurred(address provider, uint256 trustId, uint256 keyId, 
        bytes32 arn, uint256 amount, 
        uint256 keyBalance, uint256 trustBalance, uint256 ledgerBalance); 

    /**
     * withdrawalOccurred
     *
     * This event fires when assets leave a vault into an external wallet.
     *
     * @param provider address of the collateral provider that withdrew the asset 
     * @param trustId  ID of the trust that has approved the collateral provider 
     * @param keyId    keyId associated with the withdrawal
     * @param arn      asset resource name hash of the asset withdrawn 
     * @param amount   amount of asset that was withdrawn 
     * @param keyBalance    provider's total arn balance for that key
     * @param trustBalance  provider's total arn balance for that trust
     * @param ledgerBalance provider's total arn balance for the ledger
     */
    event withdrawalOccurred(address provider, uint256 trustId, uint256 keyId, 
        bytes32 arn, uint256 amount, 
        uint256 keyBalance, uint256 trustBalance, uint256 ledgerBalance); 

    /**
     * ledgerTransferOccurred
     *
     * This event fires when assets move from one key to
     * another, usually as part of receiving a trust benefit.
     *
     * @param scribe           the trusted scribe for the action 
     * @param provider         address of the contract or user that initiated the ledger transfer
     * @param arn              asset resource name of the asset that was moved
     * @param trustId          the associated trust that is being operated on
     * @param rootKeyId        keyId that will have a reduction in asset balance
     * @param keys             keyIds that will have an increase in asset balance
     * @param amounts          amount of assets to move
     * @param finalRootBalance resulting balance for the root key's arn rights
     */
    event ledgerTransferOccurred(address scribe, address provider, bytes32 arn, uint256 trustId,
        uint256 rootKeyId, uint256[] keys, uint256[] amounts, uint256 finalRootBalance); 

    ////////////////////////////////////////////////////////
    // External Methods
    //
    // These methods should be considered as the public interface
    // of the contract. They are for interaction with by wallets,
    // web frontends, and tests.
    ////////////////////////////////////////////////////////

    /**
     * notary
     *
     * @return the address of the notary in charge of transaction authorization
     */
    function notary() external view returns (address);

    /**
     * getContextArnRegistry 
     *
     * Returns a full list of assets that are being held
     * on the ledger by that key. 
     *
     * @param context LEDGER_CONTEXT_ID, TRUST_CONTEXT_ID, KEY_CONTEXT_ID 
     * @param identifier either 0, a trustId, or keyId depending on context.
     * @param provider optional collateral provider filter (or address(0))
     * @return the array of registered arns for the given context.
     */
    function getContextArnRegistry(uint256 context, uint256 identifier, address provider) 
        external view returns(bytes32[] memory);

    /**
     * getContextProviderRegistry
     *
     * Returns a list of current collateral providers for the given context,
     * and optionally a specific asset only. This does not take into consideration
     * which providers are currently trusted by the Notary. It's entirely possible
     * to have providers with assets on balance that are not currently trusted.
     *
     * @param context    LEDGER_CONTEXT_ID, TRUST_CONTEXT_ID, KEY_CONTEXT_ID
     * @param identifier either 0, a trustId, or keyId depending on context.
     * @param arn        the asset resource name to consider, or 0.
     * @return the list of provider addresses for the given context and arn.
     */
    function getContextProviderRegistry(uint256 context, uint256 identifier, bytes32 arn) 
        external view returns(address[] memory); 
        
    /**
     * getContextArnBalances
     *
     * Returns a full list of assets balances for the context. 
     *
     * @param context LEDGER_CONTEXT_ID, TRUST_CONTEXT_ID, KEY_CONTEXT_ID 
     * @param identifier either 0, a trustId, or keyId depending on context.
     * @param provider the address of the specific provider, or address(0) for all providers
     * @param arns the array of arns you want to inspect 
     * @return the array of registered arns for the given context.
     */
    function getContextArnBalances(uint256 context, uint256 identifier, 
        address provider, bytes32[] calldata arns) 
            external view returns(uint256[] memory);

    /**
     * getContextBalanceSheet
     *
     * If you find yourself calling getContextArnRegistry followed by
     * getContextArnBalances in serial, then this method will provide a full
     * arn -> balance (potentially cross sectioned by provider) balance sheet
     * for the context in a single contract call.
     *
     * Be *CAREFUL*. Where getContextArnBalances is O(n), its an N of your choosing.
     * While this is fundamentally the same thing, you don't get to decide how many
     * arns are looped through or how long the request takes. It's suggested
     * that for larger context arn sets to use the other methods.
     *
     * @param context LEDGER_CONTEXT_ID, TRUST_CONTEXT_ID, KEY_CONTEXT_ID
     * @param identifier either 0, a trustId, or keyId depending on context.
     * @param provider the address of the specific provider, or address(0) for all providers
     * @return two arrays - one of the arns in the context, the second is the balances for those arns.
     */
    function getContextBalanceSheet(uint256 context, uint256 identifier, address provider) external view
        returns(bytes32[] memory, uint256[] memory); 

    /**
     * getContextArnAllocations
     *
     * After looking at the aggregate arn balance sheet for say, a trust or
     * key context, you'll want to see an allocation across both providers
     * and their collateral balances for a given asset. 'OK I see Chainlink,
     * what is that composed of?' 'Who can withdrawal it?'.
     *
     * When done at the ledger level, is essentially a "TVL" measurement
     * of a given ARN for the entire ledger. At the trust level, it shows
     * a provider-based porfolio allocation for a given asset. 
     * At the key level, it represents withdrawal rights.
     *
     * @param context LEDGER_CONTEXT_ID, TRUST_CONTEXT_ID, KEY_CONTEXT_ID
     * @param identifier either 0, a trustId, or keyId depending on context.
     * @param arn the asset you want to inspect.i
     * @return an array of providers for the given asset
     * @return an array of their respective balances for the asset.
     */
     function getContextArnAllocations(uint256 context, uint256 identifier, bytes32 arn) external view
        returns(address[] memory, uint256[] memory);

    ////////////////////////////////////////////////////////
    // Collateral Provider External Methods
    //
    // The below methods are designed only for collateral providers 
    // because they change the key entitlements for assets.
    // 
    // These methods will panic if the message sender is not
    // an approved collateral provider for the given key's trust.
    // 
    // These method should also panic if the key isn't root.
    ////////////////////////////////////////////////////////
    
    /**
     * deposit
     *
     * Collateral providers will call deposit to update the ledger when a key
     * deposits the funds to a trust.
     *
     * All deposits must be done to the root key. And all deposits
     * must happen from approved collateral providers.
     *
     * @param rootKeyId the root key to deposit the funds into
     * @param arn       asset resource hash of the deposited asset
     * @param amount    the amount of that asset deposited.
     * @return final resulting provider arn balance for that key
     * @return final resulting provider arn balance for that trust 
     * @return final resulting provider arn balance for the ledger 
     */
    function deposit(uint256 rootKeyId, bytes32 arn, uint256 amount) external returns(uint256, uint256, uint256);

    /**
     * withdrawal 
     *
     * Collateral providers will call withdrawal to update the ledger when a key
     * withdrawals funds from a trust.
     *
     * @param keyId  key to withdrawal the funds from 
     * @param arn    asset resource hash of the withdrawn asset
     * @param amount the amount of that asset withdrawn.
     * @return final resulting provider arn balance for that key
     * @return final resulting provider arn balance for that trust 
     * @return final resulting provider arn balance for the ledger 
     */
    function withdrawal(uint256 keyId, bytes32 arn, uint256 amount) external returns(uint256, uint256, uint256);
   
    /**
     * distribute
     *
     * Funds are moved between keys to enable others the permission to withdrawal.
     * Distributions can only happen via trusted scribes, whose identifies are managed
     * by the notary. The notary must also approve the content
     * of each transaction as valid.
     *
     * The caller must be the scribe moving the funds.
     *
     * @param provider    the provider we are moving collateral for
     * @param arn         the asset we are moving
     * @param sourceKeyId the source key we are moving funds from 
     * @param keys        the destination keys we are moving funds to 
     * @param amounts     the amounts we are moving into each key 
     * @return final resulting balance of that asset for the root key 
     */
    function distribute(address provider, bytes32 arn, uint256 sourceKeyId, uint256[] calldata keys, uint256[] calldata amounts) 
        external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

///////////////////////////////////////////////////////////
// IMPORTS
///////////////////////////////////////////////////////////

/**
 * Locksmith 
 *
 * This contract has a single responsiblity: managing the lifecycle of trust keys.
 * It can mint trust keys, burn trust keys, determine ownership of trust keys, etc.
 * 
 * All the fund logic for different types of assets within a trust are within
 * a different contract, that take a dependency on the Locksmith for
 * understanding key ownership and user permissions.
 *
 */
interface ILocksmith {
    ///////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////
    
    /**
     * trustCreated
     *
     * This event is emitted when a trust is created.
     *
     * @param creator   the creator of the trust.
     * @param trustId   the resulting id of the trust (trustCount).
     * @param trustName the trust's human readable name.
     * @param recipient the address of the root key recipient
     */
    event trustCreated(address creator, uint256 trustId, bytes32 trustName, address recipient);
    
    /**
     * keyMinted
     *
     * This event is emitted when a key is minted. This event
     * is also emitted when a root key is minted upon trust creation.
     *
     * @param creator  the creator of the trust key
     * @param trustId  the trust ID they are creating the key for
     * @param keyId    the key ID that was minted by the creator
     * @param keyName  the named alias for the key given by the creator
     * @param receiver the receiving wallet address where the keyId was deposited.
     */
    event keyMinted(address creator, uint256 trustId, uint256 keyId, bytes32 keyName, address receiver);
    
    /**
     * keyBurned
     *
     * This event is emitted when a key is burned by the root key
     * holder. 
     *
     * @param rootHolder the root key holder requesting the burn 
     * @param trustId    the trust ID they are burning from 
     * @param keyId      the key ID to burn 
     * @param target     the address of the wallet that loses key access 
     * @param amount     the number of keys burned in the operation
     */
    event keyBurned(address rootHolder, uint256 trustId, uint256 keyId, address target, uint256 amount);

    ///////////////////////////////////////////////////////
    // Methods 
    ///////////////////////////////////////////////////////

    /**
     * getKeyVault
     *
     * @return the address of the dependent keyvault
     */
    function getKeyVault() external view returns (address);

    /**
     * getKeys()
     *
     * This evil bytecode is necessary to return a list of keys
     * from the Trust structure.
     *
     * @param trustId the id you want the array of keyIds for.
     * @return array of key Ids within the trust.
     */
    function getKeys(uint256 trustId) external view returns (uint256[] memory); 

    /**
     * createTrustAndRootKey
     *
     * Calling this function will create a trust with a name,
     * mint the first root key, and give it to the caller.
     *
     * @param trustName A string defining the name of the trust, like 'My Family Trust'
     * @param recipient The address to receive the root key for this trust.
     * @return the trust ID that was created
     * @return the root Key ID that was created
     */
    function createTrustAndRootKey(bytes32 trustName, address recipient) external returns (uint256, uint256);
    
    /**
     * isRootKey
     *
     * @param keyId the key id in question
     * @return true if the key Id is the root key of it's associated trust
     */
    function isRootKey(uint256 keyId) external view returns(bool); 
    
    /**
     * createKey
     *
     * The holder of a root key can use it to generate brand new keys 
     * and add them to the root key's associated trust, sending it to the 
     * destination wallets.
     *
     * This method, in batch, will mint and send 1 new ERC1155 key 
     * to each of the provided addresses.
     *
     * By default, these keys have no permissions. Those must be set up
     * seprately on the vaults or benefits themselves.
     *
     * @param rootKeyId key the sender is attempting to use to create new keys.
     * @param keyName   an alias that you want to give the key
     * @param receiver  address you want to receive an NFT key for the trust.
     * @param bind      true if you want to bind the key to the receiver
     * @return the ID of the key that was created
     */
    function createKey(uint256 rootKeyId, bytes32 keyName, address receiver, bool bind) external returns (uint256); 

    /**
     * copyKey
     *
     * The root key holder can call this method if they have an existing key
     * they want to copy. This allows multiple people to fulfill the same role,
     * share a set of benefits, or enables the root key holder to restore
     * the role for someone who lost their seed or access to their wallet.
     *
     * This method can only be invoked with a root key, which is held by
     * the message sender. The key they want to copy also must be associated
     * with the trust bound to the root key used.
     * 
     * @param rootKeyId root key to be used for this operation
     * @param keyId     key ID the message sender wishes to copy
     * @param receiver  addresses of the receivers for the copied key.
     * @param bind      true if you want to bind the key to the receiver 
     */
    function copyKey(uint256 rootKeyId, uint256 keyId, address receiver, bool bind) external;

    /**
     * soulbindKey
     *
     * This method can be called by a root key holder to make a key
     * soulbound to a specific wallet. When soulbinding a key,
     * it is not required that the current target address hold that key.
     * The amount set ensures that when sending a key of a specific
     * type, that they hold at least the amount that is bound to them.
     *
     * This code will panic if:
     *  - the caller doesn't have the root key
     *  - the target keyId doesn't exist in the trust
     *
     * @param rootKeyId the operator's root key
     * @param keyHolder the address to bind the key to
     * @param keyId     the keyId they want to bind
     * @param amount    the amount of keys to bind to the holder
     */
    function soulbindKey(uint256 rootKeyId, address keyHolder, uint256 keyId, uint256 amount) external;

    /**
     * burnKey
     *
     * The root key holder can call this method if they want to revoke
     * a key from a holder. If for some reason the holder has multiple
     * copies of this key, this method will burn them *all*.
     *
     * @param rootKeyId root key for the associated trust
     * @param keyId     id of the key you want to burn
     * @param holder    address of the holder you want to burn from
     * @param amount    the number of keys you want to burn
     */
    function burnKey(uint256 rootKeyId, uint256 keyId, address holder, uint256 amount) external;

    /**
     * inspectKey 
     * 
     * Takes a key id and inspects it.
     * 
     * @return true if the key is a valid key
     * @return alias of the key 
     * @return the trust id of the key (only if its considered valid)
     * @return true if the key is a root key
     * @return the keys associated with the given trust
     */ 
    function inspectKey(uint256 keyId) external view returns (bool, bytes32, uint256, bool, uint256[] memory);

    /**
     * validateKeyRing
     *
     * Contracts can call this method to determine if a set
     * of keys belong to the same trust.
     *
     * @param trustId   the trust ID you want to validate against
     * @param keys      the supposed keys that belong to the trust's key ring
     * @param allowRoot true if having the trust's root key on the ring is acceptable
     * @return true if valid, or will otherwise revert with a reason.
     */
    function validateKeyRing(uint256 trustId, uint256[] calldata keys, bool allowRoot) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * ICollateralProvider
 *
 * Interface that enables users to deposit and withdrawal
 * funds from their trust.
 */
interface ICollateralProvider {
    /**
     * getTrustedLedger 
     *
     * This interface must publicly expose the ledger it respects
     * to manage key distribution rights.
     *
     * @return the address of the ILedger powering the provider's key-rights.
     */
    function getTrustedLedger() external view returns (address);

    /**
     * arnWithdrawal
     *
     * Takes an ARN and sends it back to the caller. This vault will fail
     * the withdrawal if it was never deposited as it wont recognize the arn.
     *
     * @param keyId  the key you want to use to withdrawal with/from
     * @param arn    the asset resource name to withdrawal
     * @param amount the amount, in gwei, to withdrawal from the balance.
     */
    function arnWithdrawal(uint256 keyId, bytes32 arn, uint256 amount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}