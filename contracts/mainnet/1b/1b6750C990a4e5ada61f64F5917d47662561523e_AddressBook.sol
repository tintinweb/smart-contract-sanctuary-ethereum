// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/IGateKeeper.sol";


/**
 * @title Address book with portals, synthesis etc.
 *
 * @notice Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
 */
contract AddressBook is IAddressBook, Ownable {

    enum RecordTypes { Portal, Synthesis, Router, CryptoPoolAdapter, StablePoolAdapter }

    struct Record {
        /// @dev chainId chain id
        uint64 chainId;
        /// @dev portal/sinthesis address in chainId chain
        address clpEndPoint;
    }

    /// @dev chainId -> portal address
    mapping(uint64 => address) public portal;
    /// @dev chainId -> synthesis address
    mapping(uint64 => address) public synthesis;
    /// @dev chainId -> router address
    mapping(uint64 => address) public router;
    /// @dev cryptoPoolAdapter address
    mapping(uint64 => address) public cryptoPoolAdapter;
    /// @dev stablePoolAdapter address
    mapping(uint64 => address) public stablePoolAdapter;
    /// @dev treasury address
    address public treasury;
    /// @dev whitelist address
    address public whitelist;
    /// @dev gate keeper address
    address public gateKeeper;

    event PortalSet(address portal, uint64 chainId);
    event SynthesisSet(address synthesis, uint64 chainId);
    event RouterSet(address router, uint64 chainId);
    event CryptoPoolAdapterSet(address cryptoPoolAdapter, uint64 chainId);
    event StablePoolAdapterSet(address stablePoolAdapter, uint64 chainId);
    event TreasurySet(address treasury);
    event WhitelistSet(address whitelist);
    event GateKeeperSet(address gateKeeper);

    function bridge() public view returns (address bridge_) {
        if (gateKeeper != address(0)) {
            bridge_ = IGateKeeper(gateKeeper).bridge();
        }
    }

    function setPortal(Record[] memory records) external onlyOwner {
        _setRecords(portal, records, RecordTypes.Portal);
    }

    function setSynthesis(Record[] memory records) external onlyOwner {
        _setRecords(synthesis, records, RecordTypes.Synthesis);
    }

    function setRouter(Record[] memory records) external onlyOwner {
        _setRecords(router, records, RecordTypes.Router);
    }

    function setCryptoPoolAdapter(Record[] memory records) external onlyOwner {
        _setRecords(cryptoPoolAdapter, records, RecordTypes.CryptoPoolAdapter);
    }

    function setStablePoolAdapter(Record[] memory records) external onlyOwner {
        _setRecords(stablePoolAdapter, records, RecordTypes.StablePoolAdapter);
    }

    function setTreasury(address treasury_) external onlyOwner {
        _checkAddress(treasury_);
        treasury = treasury_;
        emit TreasurySet(treasury);
    }

    function setGateKeeper(address gateKeeper_) external onlyOwner {
        _checkAddress(gateKeeper_);
        gateKeeper = gateKeeper_;
        emit GateKeeperSet(gateKeeper);
    }

    function setWhitelist(address whitelist_) external onlyOwner {
        _checkAddress(whitelist_);
        whitelist = whitelist_;
        emit WhitelistSet(whitelist);
    }

    function _setRecords(mapping(uint64 => address) storage map_, Record[] memory records, RecordTypes rtype) private {
        for (uint256 i = 0; i < records.length; ++i) {
            _checkAddress(records[i].clpEndPoint);
            map_[records[i].chainId] = records[i].clpEndPoint;
            _emitEvent(records[i].clpEndPoint, records[i].chainId, rtype);
        }
    }

    function _emitEvent(address endPoint, uint64 chainId, RecordTypes rtype) private {
        if (rtype == RecordTypes.Portal) {
            emit PortalSet(endPoint, chainId);
        } else if (rtype == RecordTypes.Synthesis) {
            emit SynthesisSet(endPoint, chainId);
        } else if (rtype == RecordTypes.Router) {
            emit RouterSet(endPoint, chainId);
        } else if (rtype == RecordTypes.CryptoPoolAdapter) {
            emit CryptoPoolAdapterSet(endPoint, chainId);
        } else if (rtype == RecordTypes.StablePoolAdapter) {
            emit StablePoolAdapterSet(endPoint, chainId);
        }
    }

    function _checkAddress(address checkingAddress) private pure {
        require(checkingAddress != address(0), "AddressBook: zero address");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IAddressBook {
    /// @dev returns portal by given chainId
    function portal(uint64 chainId) external view returns (address);

    /// @dev returns synthesis by given chainId
    function synthesis(uint64 chainId) external view returns (address);

    /// @dev returns router by given chainId
    function router(uint64 chainId) external view returns (address);

    /// @dev returns cryptoPoolAdapter
    function cryptoPoolAdapter(uint64 chainId) external view returns (address);

    /// @dev returns stablePoolAdapter
    function stablePoolAdapter(uint64 chainId) external view returns (address);

    /// @dev returns whitelist
    function whitelist() external view returns (address);

    /// @dev returns treasury
    function treasury() external view returns (address);

    /// @dev returns gateKeeper
    function gateKeeper() external view returns (address);

    /// @dev returns bridge
    function bridge() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IGateKeeper {

    function calculateCost(
        address payToken,
        uint256 dataLength,
        uint64 chainIdTo,
        address sender
    ) external returns (uint256 amountToPay);

    function sendData(
        bytes calldata data,
        address to,
        uint64 chainIdTo,
        address payToken
    ) external payable;

    function getNonce() external view returns (uint256);

    function bridge() external view returns (address);
}