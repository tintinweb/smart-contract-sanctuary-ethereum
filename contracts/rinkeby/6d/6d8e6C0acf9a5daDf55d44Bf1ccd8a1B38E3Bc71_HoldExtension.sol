// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {TokenExtension, TransferData, TokenStandard} from "../../extensions/TokenExtension.sol";
import {IHoldableToken, ERC20HoldData, HoldStatusCode} from "./IHoldableToken.sol";

contract HoldExtension is TokenExtension, IHoldableToken {
    using SafeMath for uint256;
    bytes32 internal constant HOLD_DATA_SLOT =
        keccak256("consensys.contracts.token.ext.storage.holdable.data");

    struct HoldExtensionData {
        // mapping of accounts to hold data
        mapping(bytes32 => ERC20HoldData) holds;
        // mapping of accounts and their total amount on hold
        mapping(address => uint256) accountHoldBalances;
        mapping(bytes32 => bytes32) holdHashToId;
        uint256 totalSupplyOnHold;
    }

    constructor() {
        _setPackageName("net.consensys.tokenext.HoldExtension");
        _setInterfaceLabel("HoldExtension");
        _supportsTokenStandard(TokenStandard.ERC20);
        _setVersion(1);

        _registerFunction(this.hold.selector);
        _registerFunction(this.releaseHold.selector);
        _registerFunction(this.balanceOnHold.selector);
        _registerFunction(this.spendableBalanceOf.selector);
        _registerFunction(this.holdStatus.selector);
        //Need to do by name, this.executeHold.selector is ambigious
        _registerFunctionName("executeHold(bytes32)");
        _registerFunctionName("executeHold(bytes32,bytes32)");
        _registerFunctionName("executeHold(bytes32,bytes32,address)");

        _requireRole(TOKEN_CONTROLLER_ROLE);
    }

    function holdData() internal pure returns (HoldExtensionData storage ds) {
        bytes32 position = HOLD_DATA_SLOT;
        assembly {
            ds.slot := position
        }
    }

    function initialize() external override {
        _listenForTokenBeforeTransfers(this.onTransferExecuted);
        _listenForTokenApprovals(this.onApproveExecuted);
    }

    modifier isHeld(bytes32 holdId) {
        HoldExtensionData storage data = holdData();
        require(
            data.holds[holdId].status == HoldStatusCode.Ordered ||
                data.holds[holdId].status == HoldStatusCode.ExecutedAndKeptOpen,
            "Hold is not in Ordered status"
        );
        _;
    }

    function generateHoldId(
        address recipient,
        address notary,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash
    ) external pure returns (bytes32 holdId) {
        holdId = keccak256(
            abi.encodePacked(
                recipient,
                notary,
                amount,
                expirationDateTime,
                lockHash
            )
        );
    }

    /**
     * @dev Retrieve hold hash, and ID for given parameters
     */
    function retrieveHoldHashId(
        address notary,
        address sender,
        address recipient,
        uint256 value
    ) public view returns (bytes32, bytes32) {
        HoldExtensionData storage data = holdData();
        // Pack and hash hold parameters
        bytes32 holdHash = keccak256(
            abi.encodePacked(
                address(this), //Include the token address to indicate domain
                sender,
                recipient,
                notary,
                value
            )
        );
        bytes32 holdId = data.holdHashToId[holdHash];

        return (holdHash, holdId);
    }

    /**
     @notice Called by the sender to hold some tokens for a recipient that the sender can not release back to themself until after the expiration date.
     @param recipient optional account the tokens will be transferred to on execution. If a zero address, the recipient must be specified on execution of the hold.
     @param notary account that can execute the hold. Typically the recipient but can be a third party or a smart contact.
     @param amount of tokens to be transferred to the recipient on execution. Must be a non zero amount.
     @param expirationDateTime UNIX epoch seconds the held amount can be released back to the sender by the sender. Past dates are allowed.
     @param lockHash optional keccak256 hash of a lock preimage. An empty hash will not enforce the hash lock when the hold is executed.
     @return holdId a unique identifier for the hold.
     */
    function hold(
        bytes32 holdId,
        address recipient,
        address notary,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash
    ) public override returns (bool) {
        require(
            notary != address(0),
            "hold: notary must not be a zero address"
        );
        require(amount != 0, "hold: amount must be greater than zero");
        require(
            this.spendableBalanceOf(_msgSender()) >= amount,
            "hold: amount exceeds available balance"
        );

        HoldExtensionData storage data = holdData();

        (bytes32 holdHash, ) = retrieveHoldHashId(
            notary,
            _msgSender(),
            recipient,
            amount
        );

        data.holdHashToId[holdHash] = holdId;

        require(
            data.holds[holdId].status == HoldStatusCode.Nonexistent,
            "hold: id already exists"
        );
        data.holds[holdId] = ERC20HoldData(
            _msgSender(),
            recipient,
            notary,
            amount,
            expirationDateTime,
            lockHash,
            HoldStatusCode.Ordered
        );
        data.accountHoldBalances[_msgSender()] = data
            .accountHoldBalances[_msgSender()]
            .add(amount);
        data.totalSupplyOnHold = data.totalSupplyOnHold.add(amount);

        emit NewHold(
            holdId,
            recipient,
            notary,
            amount,
            expirationDateTime,
            lockHash
        );

        return true;
    }

    function retrieveHoldData(bytes32 holdId)
        external
        view
        override
        returns (ERC20HoldData memory)
    {
        HoldExtensionData storage data = holdData();
        return data.holds[holdId];
    }

    function _buildTransferWithOperatorData(
        address from,
        address to,
        uint256 amountOrTokenId,
        bytes memory data
    ) internal view returns (TransferData memory) {
        TransferData memory t = _buildTransfer(from, to, amountOrTokenId);
        t.operatorData = data;
        return t;
    }

    /**
     @notice Called by the notary to transfer the held tokens to the set at the hold recipient if there is no hash lock.
     @param holdId a unique identifier for the hold.
     */
    function executeHold(bytes32 holdId) public override {
        HoldExtensionData storage data = holdData();

        require(
            data.holds[holdId].recipient != address(0),
            "executeHold: must pass the recipient on execution as the recipient was not set on hold"
        );
        require(
            data.holds[holdId].secretHash == bytes32(0),
            "executeHold: need preimage if the hold has a lock hash"
        );

        _executeHold(holdId, "", data.holds[holdId].recipient);
    }

    /**
     @notice Called by the notary to transfer the held tokens to the recipient that was set at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a sha256 hash
     */
    function executeHold(bytes32 holdId, bytes32 lockPreimage) public override {
        HoldExtensionData storage data = holdData();

        require(
            data.holds[holdId].recipient != address(0),
            "executeHold: must pass the recipient on execution as the recipient was not set on hold"
        );
        if (data.holds[holdId].secretHash != bytes32(0)) {
            require(
                data.holds[holdId].secretHash ==
                    sha256(abi.encodePacked(lockPreimage)),
                "executeHold: preimage hash does not match lock hash"
            );
        }

        _executeHold(holdId, lockPreimage, data.holds[holdId].recipient);
    }

    /**
     @notice Called by the notary to transfer the held tokens to the recipient if no recipient was specified at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a keccak256 hash
     @param recipient the account the tokens will be transferred to on execution.
     */
    function executeHold(
        bytes32 holdId,
        bytes32 lockPreimage,
        address recipient
    ) public override {
        HoldExtensionData storage data = holdData();
        require(
            data.holds[holdId].recipient == address(0),
            "executeHold: can not set a recipient on execution as it was set on hold"
        );
        require(
            recipient != address(0),
            "executeHold: recipient must not be a zero address"
        );
        if (data.holds[holdId].secretHash != bytes32(0)) {
            require(
                data.holds[holdId].secretHash ==
                    sha256(abi.encodePacked(lockPreimage)),
                "executeHold: preimage hash does not match lock hash"
            );
        }

        data.holds[holdId].recipient = recipient;

        _executeHold(holdId, lockPreimage, recipient);
    }

    function _executeHold(
        bytes32 holdId,
        bytes32 lockPreimage,
        address recipient
    ) internal isHeld(holdId) {
        HoldExtensionData storage data = holdData();
        require(
            data.holds[holdId].notary == _msgSender(),
            "executeHold: caller must be the hold notary"
        );

        data.holds[holdId].status = HoldStatusCode.Executing;

        TransferData memory transferData = _buildTransferWithOperatorData(
            data.holds[holdId].sender,
            recipient,
            data.holds[holdId].amount,
            abi.encode(holdId)
        );
        _tokenTransfer(transferData);
        //super._transfer(holds[holdId].sender, recipient, holds[holdId].amount);

        data.holds[holdId].status = HoldStatusCode.Executed;
        data.accountHoldBalances[data.holds[holdId].sender] = data
            .accountHoldBalances[data.holds[holdId].sender]
            .sub(data.holds[holdId].amount);
        data.totalSupplyOnHold = data.totalSupplyOnHold.sub(
            data.holds[holdId].amount
        );

        (bytes32 holdHash, ) = retrieveHoldHashId(
            data.holds[holdId].notary,
            data.holds[holdId].sender,
            data.holds[holdId].recipient,
            data.holds[holdId].amount
        );

        delete data.holdHashToId[holdHash];

        emit ExecutedHold(holdId, lockPreimage, recipient);
    }

    /**
     @notice Called by the notary at any time or the sender after the expiration date to release the held tokens back to the sender.
     @param holdId a unique identifier for the hold.
     */
    function releaseHold(bytes32 holdId) public override isHeld(holdId) {
        HoldExtensionData storage data = holdData();

        if (data.holds[holdId].sender == _msgSender()) {
            require(
                block.timestamp > data.holds[holdId].expirationDateTime,
                "releaseHold: can only release after the expiration date."
            );
            data.holds[holdId].status = HoldStatusCode.ReleasedOnExpiration;
        } else if (data.holds[holdId].notary != _msgSender()) {
            revert("releaseHold: caller must be the hold sender or notary.");
        } else {
            data.holds[holdId].status = HoldStatusCode.ReleasedByNotary;
        }

        data.accountHoldBalances[data.holds[holdId].sender] = data
            .accountHoldBalances[data.holds[holdId].sender]
            .sub(data.holds[holdId].amount);
        data.totalSupplyOnHold = data.totalSupplyOnHold.sub(
            data.holds[holdId].amount
        );

        emit ReleaseHold(holdId, _msgSender());
    }

    /**
     @notice Amount of tokens owned by an account that are held pending execution or release.
     @param account owner of the tokens
     */
    function balanceOnHold(address account)
        public
        view
        override
        returns (uint256)
    {
        HoldExtensionData storage data = holdData();
        return data.accountHoldBalances[account];
    }

    /**
     @notice Total amount of tokens owned by an account including all the held tokens pending execution or release.
     @param account owner of the tokens
     */
    function spendableBalanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        HoldExtensionData storage data = holdData();
        //if (_tokenStandard() == TokenStandard.ERC20) {
        return
            _erc20Token().balanceOf(account) -
            data.accountHoldBalances[account];
        //} else {
        //TODO Add support for other tokens
        //    revert("Stnadard not supported");
        //}
    }

    function totalSupplyOnHold() external view override returns (uint256) {
        HoldExtensionData storage data = holdData();
        return data.totalSupplyOnHold;
    }

    /**
     @param holdId a unique identifier for the hold.
     @return hold status code.
     */
    function holdStatus(bytes32 holdId)
        public
        view
        override
        returns (HoldStatusCode)
    {
        HoldExtensionData storage data = holdData();
        return data.holds[holdId].status;
    }

    function onTransferExecuted(TransferData memory data)
        external
        virtual
        onlyToken
        returns (bool)
    {
        //only check if not a mint
        if (data.from != address(0)) {
            if (
                data.operatorData.length > 0 &&
                data.operator == _extensionAddress()
            ) {
                //Dont trigger normal spendableBalanceOf check
                //if we triggered this transfer as a result of _executeHold
                bytes32 holdId = abi.decode(data.operatorData, (bytes32));
                HoldExtensionData storage hd = holdData();
                require(
                    hd.holds[holdId].status == HoldStatusCode.Executing,
                    "Hold in weird state"
                );
            } else {
                require(
                    spendableBalanceOf(data.from) >= data.value,
                    "HoldableToken: amount exceeds available balance (transfer)"
                );
            }
        }
        return true;
    }

    function onApproveExecuted(TransferData memory data)
        external
        virtual
        onlyToken
        returns (bool)
    {
        require(
            spendableBalanceOf(data.from) >= data.value,
            "HoldableToken: amount exceeds available balance (approve)"
        );
        return true;
    }
}

pragma solidity ^0.8.0;

abstract contract TokenRolesConstants {
    /**
     * @dev The storage slot for the burn/burnFrom toggle
     */
    bytes32 internal constant TOKEN_ALLOW_BURN =
        keccak256("token.proxy.core.burn");
    /**
     * @dev The storage slot for the mint toggle
     */
    bytes32 internal constant TOKEN_ALLOW_MINT =
        keccak256("token.proxy.core.mint");
    /**
     * @dev The storage slot that holds the current Owner address
     */
    bytes32 internal constant TOKEN_OWNER = keccak256("token.proxy.core.owner");
    /**
     * @dev The access control role ID for the Minter role
     */
    bytes32 internal constant TOKEN_MINTER_ROLE =
        keccak256("token.proxy.core.mint.role");
    /**
     * @dev The storage slot that holds the current Manager address
     */
    bytes32 internal constant TOKEN_MANAGER_ADDRESS =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    /**
     * @dev The access control role ID for the Controller role
     */
    bytes32 internal constant TOKEN_CONTROLLER_ROLE =
        keccak256("token.proxy.controller.address");
}

pragma solidity ^0.8.0;

import {Roles} from "./Roles.sol";

abstract contract RolesBase {
    using Roles for Roles.Role;

    event RoleAdded(address indexed caller, bytes32 indexed roleId);
    event RoleRemoved(address indexed caller, bytes32 indexed roleId);

    function hasRole(address caller, bytes32 roleId)
        public
        view
        returns (bool)
    {
        return Roles.roleStorage(roleId).has(caller);
    }

    function _addRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).add(caller);

        emit RoleAdded(caller, roleId);
    }

    function _removeRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).remove(caller);

        emit RoleRemoved(caller, roleId);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function roleStorage(bytes32 _rolePosition)
        internal
        pure
        returns (Role storage ds)
    {
        bytes32 position = _rolePosition;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.8.0;

interface ITokenRoles {
    function manager() external view returns (address);

    function isController(address caller) external view returns (bool);

    function isMinter(address caller) external view returns (bool);

    function addController(address caller) external;

    function removeController(address caller) external;

    function addMinter(address caller) external;

    function removeMinter(address caller) external;

    function changeManager(address newManager) external;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title Domain-Aware contract interface
 * @notice This can be used to interact with a DomainAware contract of any type.
 * @dev An interface that represents a DomainAware contract. This interface provides
 * all public/external facing functions that the DomainAware contract implements.
 */
interface IDomainAware {
    /**
     * @dev Uses _domainName()
     * @notice The domain name for this contract used in the domain seperator.
     * This value will not change and will have a length greater than 0.
     * @return bytes The domain name represented as bytes
     */
    function domainName() external view returns (bytes memory);

    /**
     * @dev The current version for this contract. Changing this value will
     * cause the domain separator to update and trigger a cache update.
     */
    function domainVersion() external view returns (bytes32);

    /**
     * @notice Generate the domain seperator hash for this contract using the contract's
     * domain name, current domain version and the current chain-id. This call bypasses the stored cache and
     * will always represent the current domain seperator for this Contract's name + version + chain id.
     * @return bytes32 The domain seperator hash.
     */
    function generateDomainSeparator() external view returns (bytes32);

    /**
     * @notice Get the current domain seperator hash for this contract using the contract's
     * domain name, current domain version and the current chain-id.
     * @dev This call is cached by the chain-id and contract version. If these two values do not
     * change then the cached domain seperator hash is returned. If these two values do change,
     * then a new hash is generated and the cache is updated
     * @return bytes32 The current domain seperator hash
     */
    function domainSeparator() external returns (bytes32);
}

/**
 * @title Domain-Aware contract
 * @notice This should be inherited by any contract that plans on using the EIP712
 * typed structured data signing
 * @dev A generic contract to be used by contract plans on using the EIP712 typed structure
 * data signing. This contract offers a way to generate the EIP712Domain seperator for the
 * contract that extends from this.
 *
 * The EIP712 domain seperator generated depends on the domain name and domain version of the child
 * contract. Therefore, a child contract must implement the _domainName() and _domainVersion() functions in order
 * to complete the implementation.
 * The child contract may return whatever it likes for the _domainName(), however this value should not change
 * after deployment. Changing the result of the _domainName() function between calls may result in undefined behavior.
 * The _domainVersion() must be a bytes32 and that _domainName() must have a length greater than 0.
 *
 * If a child contract changes the domain version after deployment, then the domain seperator will
 * update to reflect the new version.
 *
 * This contract stores the domain seperator for each chain-id detected after deployment. This
 * means if the contract were to fork to a new blockchain with a new chain-id, then the domain-seperator
 * of this contract would update to reflect the new domain context.
 *
 */
abstract contract DomainAware is IDomainAware {
    /**
     * @dev The storage slot the DomainData is stored in this contract
     */
    bytes32 internal constant _DOMAIN_AWARE_SLOT =
        keccak256("domainaware.data");

    /**
     * @dev The cached DomainData for this chain & contract version.
     * @param domainSeparator The cached domainSeperator for this chain + contract version
     * @param version The contract version this DomainData is for
     */
    struct DomainData {
        bytes32 domainSeparator;
        bytes32 version;
    }

    /**
     * @dev The struct storing all the DomainData cached for each chain-id.
     * This is a very gas efficient way to not recalculate the domain separator
     * on every call, while still automatically detecting ChainID changes.
     * @param chainToDomainData Mapping of ChainID to domain separators.
     */
    struct DomainAwareData {
        mapping(uint256 => DomainData) chainToDomainData;
    }

    /**
     * @dev If in the constructor we have a non-zero domain name, then update the domain seperator now.
     * Otherwise, the child contract will need to do this themselves
     */
    constructor() {
        if (_domainName().length > 0) {
            _updateDomainSeparator();
        }
    }

    /**
     * @dev The domain name for this contract. This value should not change at all and should have a length
     * greater than 0.
     * Changing this value changes the domain separator but does not trigger a cache update so may
     * result in undefined behavior
     * TODO Fix cache issue? Gas inefficient since we don't know if the data has updated?
     * We can't make this pure because ERC20 requires name() to be view.
     * @return bytes The domain name represented as a bytes
     */
    function _domainName() internal view virtual returns (bytes memory);

    /**
     * @dev The current version for this contract. Changing this value will
     * cause the domain separator to update and trigger a cache update.
     */
    function _domainVersion() internal view virtual returns (bytes32);

    /**
     * @dev Uses _domainName()
     * @notice The domain name for this contract used in the domain seperator.
     * This value will not change and will have a length greater than 0.
     * @return bytes The domain name represented as bytes
     */
    function domainName() external view override returns (bytes memory) {
        return _domainName();
    }

    /**
     * @dev Uses _domainName()
     * @notice The current version for this contract. This is the domain version
     * used in the domain seperator
     */
    function domainVersion() external view override returns (bytes32) {
        return _domainVersion();
    }

    /**
     * @dev Get the DomainAwareData struct stored in this contract.
     */
    function _domainAwareData()
        private
        pure
        returns (DomainAwareData storage ds)
    {
        bytes32 position = _DOMAIN_AWARE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Generate the domain seperator hash for this contract using the contract's
     * domain name, current domain version and the current chain-id. This call bypasses the stored cache and
     * will always represent the current domain seperator for this Contract's name + version + chain id.
     * @return bytes32 The domain seperator hash.
     */
    function generateDomainSeparator() public view override returns (bytes32) {
        uint256 chainID = _chainID();
        bytes memory dn = _domainName();
        bytes memory dv = abi.encodePacked(_domainVersion());
        require(dn.length > 0, "Domain name is empty");
        require(dv.length > 0, "Domain version is empty");

        // no need for assembly, running very rarely
        bytes32 domainSeparatorHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(dn), // ERC-20 Name
                keccak256(dv), // Version
                chainID,
                address(this)
            )
        );

        return domainSeparatorHash;
    }

    /**
     * @notice Get the current domain seperator hash for this contract using the contract's
     * domain name, current domain version and the current chain-id.
     * @dev This call is cached by the chain-id and contract version. If these two values do not
     * change then the cached domain seperator hash is returned. If these two values do change,
     * then a new hash is generated and the cache is updated
     * @return bytes32 The current domain seperator hash
     */
    function domainSeparator() public override returns (bytes32) {
        return _domainSeparator();
    }

    /**
     * @dev Generate and update the cached domain seperator hash for this contract
     * using the contract's domain name, current domain version and the current chain-id.
     * This call will always overwrite the cache even if the cached data of the same.
     * @return bytes32 The current domain seperator hash that was stored in cache
     */
    function _updateDomainSeparator() internal returns (bytes32) {
        uint256 chainID = _chainID();

        bytes32 newDomainSeparator = generateDomainSeparator();

        require(newDomainSeparator != bytes32(0), "Invalid domain seperator");

        _domainAwareData().chainToDomainData[chainID] = DomainData(
            newDomainSeparator,
            _domainVersion()
        );

        return newDomainSeparator;
    }

    /**
     * @dev Get the current domain seperator hash for this contract using the contract's
     * domain name, current domain version and the current chain-id.
     * This call is cached by the chain-id and contract version. If these two values do not
     * change then the cached domain seperator hash is returned. If these two values do change,
     * then a new hash is generated and the cache is updated
     * @return bytes32 The current domain seperator hash
     */
    function _domainSeparator() private returns (bytes32) {
        uint256 chainID = _chainID();
        bytes32 reportedVersion = _domainVersion();

        DomainData memory currentDomainData = _domainAwareData()
            .chainToDomainData[chainID];

        if (
            currentDomainData.domainSeparator != 0x00 &&
            currentDomainData.version == reportedVersion
        ) {
            return currentDomainData.domainSeparator;
        }

        return _updateDomainSeparator();
    }

    /**
     * @dev Get the current chain-id. This is done using the chainid opcode.
     * @return uint256 The current chain-id as a number.
     */
    function _chainID() internal view returns (uint256) {
        uint256 chainID;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainID := chainid()
        }

        return chainID;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IToken} from "../IToken.sol";
import {ITokenRoles} from "../../utils/roles/ITokenRoles.sol";
import {IDomainAware} from "../../utils/DomainAware.sol";

interface ITokenProxy is IToken, ITokenRoles, IDomainAware {
    fallback() external payable;

    receive() external payable;

    function upgradeTo(address logic, bytes memory data) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

abstract contract TokenEventConstants {
    /**
     * @dev The event hash for a token transfer event to be used by the ExtendableEventManager
     * and any extensions wanting to listen to the event
     */
    bytes32 internal constant TOKEN_TRANSFER_EVENT =
        keccak256("token.events.transfer");

    /**
     * @dev The event hash for a token transfer event to be used by the ExtendableEventManager
     * and any extensions wanting to listen to the event
     */
    bytes32 internal constant TOKEN_BEFORE_TRANSFER_EVENT =
        keccak256("consensys.contracts.token.events.before.transfer");

    /**
     * @dev The event hash for a token approval event to be used by the ExtendableEventManager
     * and any extensions wanting to listen to the event
     */
    bytes32 internal constant TOKEN_APPROVE_EVENT =
        keccak256("token.events.approve");
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {TransferData} from "../IToken.sol";

interface ITokenEventManager {
    function on(
        bytes32 eventId,
        function(TransferData memory) external returns (bool) callback
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev A struct containing information about the current token transfer.
 * @param token Token address that is executing this extension.
 * @param payload The full payload of the initial transaction.
 * @param partition Name of the partition (left empty for ERC20 transfer).
 * @param operator Address which triggered the balance decrease (through transfer or redemption).
 * @param from Token holder.
 * @param to Token recipient for a transfer and 0x for a redemption.
 * @param value Number of tokens the token holder balance is decreased by.
 * @param data Extra information (if any).
 * @param operatorData Extra information, attached by the operator (if any).
 */
struct TransferData {
    address token;
    bytes payload;
    bytes32 partition;
    address operator;
    address from;
    address to;
    uint256 value;
    uint256 tokenId;
    bytes data;
    bytes operatorData;
}

/**
 * @notice An enum of different token standards by name
 */
enum TokenStandard {
    ERC20,
    ERC721,
    ERC1400,
    ERC1155
}

/**
 * @title Token Interface
 * @dev A standard interface all token standards must inherit from. Provides token standard agnostic
 * functions
 */
interface IToken {
    /**
     * @notice Perform a transfer given a TransferData struct. Only addresses with the token controllers
     * role should be able to invoke this function.
     * @return bool If this contract does not support the transfer requested, it should return false.
     * If the contract does support the transfer but the transfer is impossible, it should revert.
     * If the contract does support the transfer and successfully performs the transfer, it should return true
     */
    function tokenTransfer(TransferData calldata transfer)
        external
        returns (bool);

    /**
     * @notice A function to determine what token standard this token implements. This
     * is a pure function, meaning the value should not change
     * @return TokenStandard The token standard this token implements
     */
    function tokenStandard() external pure returns (TokenStandard);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ExtensionBase} from "./ExtensionBase.sol";
import {IExtension, TransferData, TokenStandard} from "./IExtension.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RolesBase} from "../utils/roles/RolesBase.sol";
import {IERC20Extendable} from "../IERC20Extendable.sol";
import {TokenRolesConstants} from "../utils/roles/TokenRolesConstants.sol";
import {IToken} from "../tokens/IToken.sol";
import {ITokenEventManager} from "../tokens/eventmanager/ITokenEventManager.sol";
import {TokenEventConstants} from "../tokens/eventmanager/TokenEventConstants.sol";

/**
 * @title Token Extension Contract
 * @notice This shouldn't be used directly, it should be extended by child contracts
 * @dev This contract setups the base of every Token Extension contract. It
 * defines a set data structure for holding important information about
 * the current Extension registration instance. This includes the extension
 * supported token standards, function signatures, supported interfaces,
 * deployer address and extension version.
 *
 * The TokenExtension also defines three functions that allow extensions to register
 * callbacks to specific events: _listenForTokenTransfers, _listenForTokenBeforeTransfers,
 * _listenForTokenApprovals
 *
 * The ExtensionBase also provides several function modifiers to restrict function
 * invokation
 */
abstract contract TokenExtension is
    TokenRolesConstants,
    TokenEventConstants,
    IExtension,
    ExtensionBase,
    RolesBase
{
    // map of supported token standards
    mapping(TokenStandard => bool) private _supportedTokenStandards;
    //Should only be modified inside the constructor
    bytes4[] private _exposedFuncSigs;
    mapping(bytes4 => bool) private _interfaceMap;
    bytes32[] private _requiredRoles;
    address private _deployer;
    uint256 private _version;
    string private _package;
    bytes32 private _packageHash;
    string private _interfaceLabel;

    /**
     * @dev Invoke TokenExtension constructor and set the deployer as well as register
     * the packageHash
     */
    constructor() {
        _deployer = msg.sender;
        __update_package_hash();
    }

    /**
     * @dev Generates a hash given the deployer and package name
     */
    function __update_package_hash() private {
        _packageHash = keccak256(abi.encodePacked(_deployer, _package));
    }

    /**
     * @dev Sets the package version. Can only be called within
     * the constructor
     * @param __version version of the extension being deployed
     */
    function _setVersion(uint256 __version) internal {
        require(
            _isInsideConstructorCall(),
            "Function must be called inside the constructor"
        );

        _version = __version;
    }

    /**
     * @dev Sets the package name. Can only be called within
     * the constructor
     * @param package name of the extension being deployed
     */
    function _setPackageName(string memory package) internal {
        require(
            _isInsideConstructorCall(),
            "Function must be called inside the constructor"
        );

        _package = package;

        __update_package_hash();
    }

    /**
     * @dev Sets token standard as supported. Can only be called
     * within the constructor. Valid token standards referenced in
     * the TokenStandards enum
     * @param tokenStandard a valid token standard that the extension supports.
     */
    function _supportsTokenStandard(TokenStandard tokenStandard) internal {
        require(
            _isInsideConstructorCall(),
            "Function must be called inside the constructor"
        );
        _supportedTokenStandards[tokenStandard] = true;
    }

    /**
     * @dev Sets the interface label of the extension. Can only be
     * called within the constructor and should be called for
     * every extension.
     * @param interfaceLabel_ the interface label.
     */
    function _setInterfaceLabel(string memory interfaceLabel_) internal {
        require(
            _isInsideConstructorCall(),
            "Function must be called inside the constructor"
        );

        _interfaceLabel = interfaceLabel_;
    }

    /**
     * @dev Sets all valid token standard as supported. Can only
     * be called within the constructor.
     */
    function _supportsAllTokenStandards() internal {
        _supportsTokenStandard(TokenStandard.ERC20);
        _supportsTokenStandard(TokenStandard.ERC721);
        _supportsTokenStandard(TokenStandard.ERC1400);
        _supportsTokenStandard(TokenStandard.ERC1155);
    }

    /**
     * @notice Gets the extension deployer address
     * @return the extension deployer address
     */
    function extensionDeployer() external view override returns (address) {
        return _deployer;
    }

    /**
     * @notice Gets the package hash (generated using the package name and
     * deployer address)
     * @return the package hash
     */
    function packageHash() external view override returns (bytes32) {
        return _packageHash;
    }

    /**
     * @notice Gets the package version
     * @return the package version
     */
    function version() external view override returns (uint256) {
        return _version;
    }

    /**
     * @notice Checks if token standard is supported by the extension
     * @param standard a valid TokenStandard (enum)
     * @return a bool. True if the token standard is supported. False otherwise
     */
    function isTokenStandardSupported(TokenStandard standard)
        external
        view
        override
        returns (bool)
    {
        return _supportedTokenStandards[standard];
    }

    /**
     * @dev A function modifier to only allow the token owner to execute this function
     */
    modifier onlyOwner() {
        require(
            _msgSender() == _tokenOwner(),
            "Only the token owner can invoke"
        );
        _;
    }

    /**
     * @dev A function modifier to only allow the token owner or the address
     * that registered the extension to execute this function
     */
    modifier onlyTokenOrOwner() {
        address msgSender = _msgSender();
        require(
            msgSender == _tokenOwner() || msgSender == _tokenAddress(),
            "Only the token or token owner can invoke"
        );
        _;
    }

    /**
     * @dev Specify a token role Id that this extension requires. For example
     * if an extension needs to mint tokens then it should require TOKEN_MINTER_ROLE.
     * Can only be called within the constructor.
     * @param roleId the role id.
     */
    function _requireRole(bytes32 roleId) internal {
        require(
            _isInsideConstructorCall(),
            "Function must be called inside the constructor"
        );
        _requiredRoles.push(roleId);
    }

    /**
     * @dev Specify a specific interface label that this extension supports.
     * Can only be called within the constructor.
     * @param interfaceId the interface id.
     */
    function _supportInterface(bytes4 interfaceId) internal {
        require(
            _isInsideConstructorCall(),
            "Function must be called inside the constructor"
        );
        _interfaceMap[interfaceId] = true;
    }

    /**
     * @dev Same as `_registerFunction(bytes4)`, however
     * lets you specify a function by its function signature.
     * Can only be called within the constructor.
     * @param selector the extension function signature.
     */
    function _registerFunctionName(string memory selector) internal {
        _registerFunction(bytes4(keccak256(abi.encodePacked(selector))));
    }

    /**
     * @dev Register a function selector to be added to the token.
     * If this function is invoked on the token, then this extension
     * instance will be invoked. Can only be called within the constructor.
     * @param selector the extension function selector.
     */
    function _registerFunction(bytes4 selector) internal {
        require(
            _isInsideConstructorCall(),
            "Function must be called inside the constructor"
        );
        _exposedFuncSigs.push(selector);
    }

    /**
     * @notice An array of function signatures registered by the extension
     * @dev This function is used by the TokenProxy to determine what
     * function selectors to add to the TokenProxy
     * @return An array containing the function signatures registered by the extension
     */
    function externalFunctions()
        external
        view
        override
        returns (bytes4[] memory)
    {
        return _exposedFuncSigs;
    }

    /**
     * @notice Gets the list of required roles required to call the extension
     * @return a bytes32 array. The required roles in order to call the extension
     */
    function requiredRoles() external view override returns (bytes32[] memory) {
        return _requiredRoles;
    }

    /**
     * @dev Checks if execution context is within the contract constructor
     * @return bool. True if within the constructor, false otherwise.
     */
    function _isInsideConstructorCall() internal view returns (bool) {
        uint256 size;
        address addr = address(this);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(addr)
        }
        return size == 0;
    }

    /**
     * @notice The ERC1820 interface label the extension will be registered as
     * in the ERC1820 registry
     */
    function interfaceLabel() external view override returns (string memory) {
        return _interfaceLabel;
    }

    /**
     * @dev Checks if address is the token owner
     * @param addr address
     * @return bool. True if address is token owner, false otherwise.
     */
    function _isTokenOwner(address addr) internal view returns (bool) {
        return addr == _tokenOwner();
    }

    // TODO Move to specific Erc20TokenExtension contract?!?
    /**
     * @dev Explicit method for erc20 tokens. I returns an erc20 proxy contract interface
     * @return IERC20Proxy. Returns an erc20 proxy contract interface.
     */
    function _erc20Token() internal view returns (IERC20Extendable) {
        return IERC20Extendable(_tokenAddress());
    }

    /**
     * @dev Get the current owner address of the registered token
     * @return address. Owner address of the registered token
     */
    function _tokenOwner() internal view returns (address) {
        Ownable token = Ownable(_tokenAddress());

        return token.owner();
    }

    /**
     * @dev Creates a TransferData structure, to be used as an argument for tokenTransfer
     * function. Also it is relevant to point out that TransferData supports
     * all token standards available in this enum TokenStandard
     * @return TransferData struct.
     */
    function _buildTransfer(
        address from,
        address to,
        uint256 amountOrTokenId
    ) internal view returns (TransferData memory) {
        uint256 amount = amountOrTokenId;
        uint256 tokenId = 0;
        if (_tokenStandard() == TokenStandard.ERC721) {
            amount = 0;
            tokenId = amountOrTokenId;
        }

        address token = _tokenAddress();
        return
            TransferData(
                token,
                _msgData(),
                bytes32(0),
                _extensionAddress(),
                from,
                to,
                amount,
                tokenId,
                bytes(""),
                bytes("")
            );
    }

    /**
     * @dev Perform a transfer given a TransferData struct. Only addresses with the
     * token controllers role should be able to invoke this function.
     * @return bool If this contract does not support the transfer requested, it should return false.
     * If the contract does support the transfer but the transfer is impossible, it should revert.
     * If the contract does support the transfer and successfully performs the transfer, it should return true
     */
    function _tokenTransfer(TransferData memory tdata) internal returns (bool) {
        return IToken(_tokenAddress()).tokenTransfer(tdata);
    }

    /**
     * @dev Listen for token transfers and invoke the provided callback function.
     * When the callback is invoked, the transfer has already occured.
     * It is important that the callback has the onlyToken modifier in order to ensure that
     * only the token can execute the callback function.
     * @param callback an external/public function that has TransferData as argument.
     */
    function _listenForTokenTransfers(
        function(TransferData memory) external returns (bool) callback
    ) internal {
        ITokenEventManager eventManager = ITokenEventManager(_tokenAddress());

        eventManager.on(TOKEN_TRANSFER_EVENT, callback);
    }

    /**
     * @dev Listen for token approvals and invoke the provided callback function.
     * When the callback is invoked, the approval has already occured.
     * It is important that the callback has the onlyToken modifier in order to ensure that
     * only the token can execute the callback function.
     * @param callback an external/public function that has TransferData as argument.
     */
    function _listenForTokenBeforeTransfers(
        function(TransferData memory) external returns (bool) callback
    ) internal {
        ITokenEventManager eventManager = ITokenEventManager(_tokenAddress());
        eventManager.on(TOKEN_BEFORE_TRANSFER_EVENT, callback);
    }

    /**
     * @dev Listen for token transfers and invoke the provided callback function.
     * The callback is invoked right before the transfer occurs.
     * It is important that the callback has the onlyToken modifier in order to ensure that
     * only the token can execute the callback function
     * @param callback an external/public function that has TransferData as argument.
     */
    function _listenForTokenApprovals(
        function(TransferData memory) external returns (bool) callback
    ) internal {
        ITokenEventManager eventManager = ITokenEventManager(_tokenAddress());

        eventManager.on(TOKEN_APPROVE_EVENT, callback);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {TokenStandard} from "../tokens/IToken.sol";

/**
 * @title Extension Metadata Interface
 * @dev An interface that extensions must implement that provides additional
 * metadata about the extension.
 */
interface IExtensionMetadata {
    /**
     * @notice An array of function signatures this extension adds when
     * registered when a TokenProxy
     * @dev This function is used by the TokenProxy to determine what
     * function selectors to add to the TokenProxy
     */
    function externalFunctions() external view returns (bytes4[] memory);

    /**
     * @notice An array of role IDs that this extension requires from the Token
     * in order to function properly
     * @dev This function is used by the TokenProxy to determine what
     * roles to grant to the extension after registration and what roles to remove
     * when removing the extension
     */
    function requiredRoles() external view returns (bytes32[] memory);

    /**
     * @notice Whether a given Token standard is supported by this Extension
     * @param standard The standard to check support for
     */
    function isTokenStandardSupported(TokenStandard standard)
        external
        view
        returns (bool);

    /**
     * @notice The address that deployed this extension.
     */
    function extensionDeployer() external view returns (address);

    /**
     * @notice The hash of the package string this extension was deployed with
     */
    function packageHash() external view returns (bytes32);

    /**
     * @notice The version of this extension, represented as a number
     */
    function version() external view returns (uint256);

    /**
     * @notice The ERC1820 interface label the extension will be registered as in the ERC1820 registry
     */
    function interfaceLabel() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {TransferData} from "../tokens/IToken.sol";
import {IExtensionMetadata, TokenStandard} from "./IExtensionMetadata.sol";

/**
 * @title Extension Interface
 * @dev An interface to be implemented by Extensions
 */
interface IExtension is IExtensionMetadata {
    /**
     * @notice This function cannot be invoked directly
     * @dev This function is invoked when the Extension is registered
     * with a TokenProxy
     */
    function initialize() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {TokenStandard} from "./IExtension.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title Extension Base Contract
 * @notice This shouldn't be used directly, it should be extended by child contracts
 * @dev This contract setups the base of every Extension contract (including proxies). It
 * defines a set data structure for holding important information about the current Extension
 * registration instance. This includes the current Token address, the current Extension
 * global address and an "authorized caller" (callsite).
 *
 * The ExtensionBase also defines a _msgSender() function, this function should be used
 * instead of the msg.sender variable. _msgSender() has a different behavior depending
 * on who the msg.sender variable is, this is to allow both meta-transactions and
 * proxy forwarding
 *
 * The "callsite" should be considered an admin-style address. See
 * ExtensionProxy for more information
 *
 * The ExtensionBase also provides several function modifiers to restrict function
 * invokation
 */
abstract contract ExtensionBase is ContextUpgradeable {
    bytes32 internal constant _PROXY_DATA_SLOT = keccak256("ext.proxy.data");

    /**
     * @dev Considered the storage to be shared between the proxy
     * and extension logic contract.
     * We share this information with the logic contract because it may
     * be useful for the logic contract to query this information
     * @param token The token address that registered this extension instance
     * @param extension The extension logic contract to use
     * @param callsite The "admin" of this registered extension instance
     * @param initialized Whether this instance is initialized
     */
    struct ProxyData {
        address token;
        address extension;
        address callsite;
        bool initialized;
        TokenStandard standard;
    }

    /**
     * @dev The ProxyData struct stored in this registered Extension instance.
     */
    function _proxyData() internal pure returns (ProxyData storage ds) {
        bytes32 position = _PROXY_DATA_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev The current Extension logic contract address
     */
    function _extensionAddress() internal view returns (address) {
        ProxyData storage ds = _proxyData();
        return ds.extension;
    }

    /**
     * @dev The current token address that registered this extension instance
     */
    function _tokenAddress() internal view returns (address payable) {
        ProxyData storage ds = _proxyData();
        return payable(ds.token);
    }

    /**
     * @dev The current token standard that registered this extension instance
     * @return a token standard
     */
    function _tokenStandard() internal view returns (TokenStandard) {
        ProxyData storage ds = _proxyData();
        return ds.standard;
    }

    /**
     * @dev The current admin address for this registered extension instance
     */
    function _authorizedCaller() internal view returns (address) {
        ProxyData storage ds = _proxyData();
        return ds.callsite;
    }

    /**
     * @dev A function modifier to only allow the registered token to execute this function
     */
    modifier onlyToken() {
        require(msg.sender == _tokenAddress(), "Token: Unauthorized");
        _;
    }

    /**
     * @dev A function modifier to only allow the admin to execute this function
     */
    modifier onlyAuthorizedCaller() {
        require(msg.sender == _authorizedCaller(), "Caller: Unauthorized");
        _;
    }

    /**
     * @dev A function modifier to only allow the admin or ourselves to execute this function
     */
    modifier onlyAuthorizedCallerOrSelf() {
        require(
            msg.sender == _authorizedCaller() || msg.sender == address(this),
            "Caller: Unauthorized"
        );
        _;
    }

    /**
     * @dev Get the current msg.sender for the current CALL context
     */
    function _msgSender() internal view virtual override returns (address ret) {
        if (msg.data.length >= 24 && msg.sender == _authorizedCaller()) {
            // At this point we know that the sender is a token proxy,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data

            // solhint-disable-next-line no-inline-assembly
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "./HoldStatusCode.sol";

struct ERC20HoldData {
    address sender;
    address recipient;
    address notary;
    uint256 amount;
    uint256 expirationDateTime;
    bytes32 secretHash;
    HoldStatusCode status;
}

/**
 * @title Holdable ERC20 Token Interface.
 * @dev like approve except the tokens can't be spent by the sender while they are on hold.
 */
interface IHoldableToken {
    event NewHold(
        bytes32 indexed holdId,
        address indexed recipient,
        address indexed notary,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash
    );
    event ExecutedHold(
        bytes32 indexed holdId,
        bytes32 lockPreimage,
        address recipient
    );
    event ReleaseHold(bytes32 indexed holdId, address sender);

    /**
     @notice Called by the sender to hold some tokens for a recipient that the sender can not release back to themself until after the expiration date.
     @param recipient optional account the tokens will be transferred to on execution. If a zero address, the recipient must be specified on execution of the hold.
     @param notary account that can execute the hold. Typically the recipient but can be a third party or a smart contact.
     @param amount of tokens to be transferred to the recipient on execution. Must be a non zero amount.
     @param expirationDateTime UNIX epoch seconds the held amount can be released back to the sender by the sender. Past dates are allowed.
     @param lockHash optional keccak256 hash of a lock preimage. An empty hash will not enforce the hash lock when the hold is executed.
     @return bool Whether the call was successful or not.
     */
    function hold(
        bytes32 holdId,
        address recipient,
        address notary,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash
    ) external returns (bool);

    function retrieveHoldData(bytes32 holdId)
        external
        view
        returns (ERC20HoldData memory);

    /**
     @notice Called by the notary to transfer the held tokens to the set at the hold recipient if there is no hash lock.
     @param holdId a unique identifier for the hold.
     */
    function executeHold(bytes32 holdId) external;

    /**
     @notice Called by the notary to transfer the held tokens to the recipient that was set at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a keccak256 hash
     */
    function executeHold(bytes32 holdId, bytes32 lockPreimage) external;

    /**
     @notice Called by the notary to transfer the held tokens to the recipient if no recipient was specified at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a keccak256 hash
     @param recipient the account the tokens will be transferred to on execution.
     */
    function executeHold(
        bytes32 holdId,
        bytes32 lockPreimage,
        address recipient
    ) external;

    /**
     @notice Called by the notary at any time or the sender after the expiration date to release the held tokens back to the sender.
     @param holdId a unique identifier for the hold.
     */
    function releaseHold(bytes32 holdId) external;

    /**
     @notice Amount of tokens owned by an account that are held pending execution or release.
     @param account owner of the tokens
     */
    function balanceOnHold(address account) external view returns (uint256);

    /**
     @notice Total amount of tokens owned by an account including all the held tokens pending execution or release.
     @param account owner of the tokens
     */
    function spendableBalanceOf(address account)
        external
        view
        returns (uint256);

    function totalSupplyOnHold() external view returns (uint256);

    /**
     @param holdId a unique identifier for the hold.
     @return hold status code.
     */
    function holdStatus(bytes32 holdId) external view returns (HoldStatusCode);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

enum HoldStatusCode {
    Nonexistent,
    Ordered,
    Executed,
    ExecutedAndKeptOpen,
    ReleasedByNotary,
    ReleasedByPayee,
    ReleasedOnExpiration,
    Executing
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ITokenProxy} from "./tokens/proxy/ITokenProxy.sol";

/**
 * @title Extendable ERC20 Proxy Interface
 * @notice An interface to interact with an ERC20 Token (proxy).
 */
interface IERC20Extendable is IERC20Metadata, ITokenProxy {
    /**
     * @notice Returns true if minting is allowed on this token, otherwise false
     */
    function mintingAllowed() external view returns (bool);

    /**
     * @notice Returns true if burning is allowed on this token, otherwise false
     */
    function burningAllowed() external view returns (bool);

    /**
     * @notice Returns the maximum value the totalSupply() can be for this token
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Creates `amount` new tokens for `to`.
     *
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * @param to The address to mint tokens to
     * @param amount The amount of new tokens to mint
     */
    function mint(address to, uint256 amount) external returns (bool);

    /**
     * @notice Destroys `amount` tokens from the caller.
     *
     * @dev See {ERC20-_burn}.
     * @param amount The amount of tokens to burn from the caller.
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @notice Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * @dev See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @param spender The address that will be given the allownace increase
     * @param addedValue How much the allowance should be increased by
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * @param spender The address that will be given the allownace decrease
     * @param subtractedValue How much the allowance should be decreased by
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
library StorageSlot {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}