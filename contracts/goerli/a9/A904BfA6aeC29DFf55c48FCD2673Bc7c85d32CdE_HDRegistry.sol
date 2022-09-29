// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

// MMMMMNo.   ,0MMMMMMWo.   :XMMMXc.                        .oNMMMMM
// MMMMXl.   ;0WMMMMMNd.   ;0WMMXl.                          .lXMMMM
// MMWO,   .oXMMMMMMXl.   cXMMMMKxoooooooooo;    .coooooooc.   ,OWMM
// MXo.   ,OWMMMMMMK:   .oNMMMMMMMMMMMMMMMMMNo.   :KMMMMMMWO,   .oXM
// 0;    .:oooooool'   .xWMMMMMMMMMMMMMMMMMMMWk.   ,OWMMMMMMXl.   ;0
// ,                  .oWMMMMMMMMMMMMMMMMMMMMMWo.   ;KMMMMMMMXc    ,
// k,     .;;;;;;;;.   .dNMMMMMMMMMMMMMMMMMMMNd.   'kWMMMMMWKc.   ,k
// MXo.   .oXWWWWWWK:    :KMMMMMMMMMMMMMMMMMK:    :KMMMMMMXd.   .oXM
// MMW0c.   ,kWMMMMMNd.   'kWMMMMMMMMMMMMMWk'   .dNMMMMMWk,   .c0WMM
// MMMMWk,   .c0WMMMMW0;   .lXMMMMMMMMMMMXl.   ;0WMMMMW0c.   ,kWMMMM
// MMMMMMXd.   .oXMMMMMXo.   ,OWMMMMMMMWO,   .oXMMMMMXo.   .oXMMMMMM
// MMMMMMMW0c.   ,kNMMMMWk,   .oNMMMMMNd.   ,kWMMMMNk,   .c0WMMMMMMM
// MMMMMMMMMWk,   .c0WMMMMKc.   :0WMMMNd. .cKMMMMW0c.   ,kWMMMMMMMMM
// MMMMMMMMMMMXd.   .oXMMMMNx.   .xXNMMWOlxNMMMMXo.   .dXMMMMMMMMMMM
// MMMMMMMMMMMMWKc.   ,kNMMMW0:   ..cXMMMWMMMMNk,   .cKWMMMMMMMMMMMM
// MMMMMMMMMMMMMMWk,   .:0WMMMNo.    ,OWMMMMW0:.   ,kWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMXd.   .oXMMMWO,    .oXMMXo.   .dXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWKc.   ,kNMMMXl'.   :Ox,   .cKWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWO;   .:0WMMWXk'        ;OWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMXd.   .dNMMMMK:     .dXMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWKc. .dNMMMMMNd. .cKWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMNd,xWMMMMMMMWx,dNMMMMMMMMMMMMMMMMMMMMMMMM

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IHDRegistry.sol";

error CannotBeZeroAddress();
error NoRecordAvailable();
error DataCannotBeEmpty();

contract HDRegistry is Ownable, IHDRegistry {
    bytes32 private HASH_ZERO =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    mapping(address => mapping(uint256 => HDNFT)) private hdNFTs;
    mapping(address => uint256[]) private tokensByAddress;

    function addEntry(
        address _owner,
        address _nftContract,
        bytes32 _hashedData,
        uint256 _tokenId,
        AssignedRights _rights,
        StatusType _status
    ) external onlyOwner {
        if (_nftContract == address(0) || _owner == address(0))
            revert CannotBeZeroAddress();
        if (_hashedData == HASH_ZERO) revert DataCannotBeEmpty();

        hdNFTs[_nftContract][_tokenId] = HDNFT(_owner, _hashedData, _rights, _status);
        tokensByAddress[_nftContract].push(_tokenId);

        emit AddEntry(_owner, _nftContract, _tokenId, _hashedData, _rights, _status);
    }

    function updateEntry(
        address _owner,
        address _nftContract,
        bytes32 _hashedData,
        uint256 _tokenId,
        AssignedRights _rights,
        StatusType _status
    ) external onlyOwner {
        if (_nftContract == address(0)) revert CannotBeZeroAddress();

        HDNFT storage hdNFT = hdNFTs[_nftContract][_tokenId];

        if (hdNFT.hashedData == HASH_ZERO) revert NoRecordAvailable();

        hdNFT.hashedData = _hashedData;
        hdNFT.owner = _owner;
        hdNFT.rights = _rights;
        hdNFT.status = _status;

        emit UpdateEntry(_owner, _nftContract, _tokenId, _hashedData, _rights, _status);
    }

    function getEntry(uint256 _tokenId, address _nftContract)
        external
        view
        returns (HDNFT memory)
    {
        return hdNFTs[_nftContract][_tokenId];
    }

    function getEntriesByContract(address _nftContract)
        external
        view
        returns (HDNFT[] memory)
    {
        uint256[] memory tokenIds = tokensByAddress[_nftContract];
        HDNFT[] memory entries = new HDNFT[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            entries[i] = hdNFTs[_nftContract][tokenIds[i]];
        }
        return entries;
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
pragma solidity >=0.8.12 <0.9.0;

interface IHDRegistry {
    enum AssignedRights {
        None,
        Minimal,
        Exhibition,
        Commercial,
        Reproduction,
        Modification,
        All
    }

    enum StatusType {
        Normal,
        Blacklisted,
        Deleted
    }

    struct HDNFT {
        address owner;
        bytes32 hashedData;
        AssignedRights rights;
        StatusType status;
    }

    event AddEntry(
        address owner,
        address nftContract,
        uint256 tokenId,
        bytes32 hashedData,
        AssignedRights rights,
        StatusType status
    );

    event UpdateEntry(
        address owner,
        address nftContract,
        uint256 tokenId,
        bytes32 hashedData,
        AssignedRights rights,
        StatusType status
    );

    function addEntry(
        address _owner,
        address _nftContract,
        bytes32 _hashedData,
        uint256 _tokenId,
        AssignedRights _rights,
        StatusType _status
    ) external;

    function updateEntry(
        address _owner,
        address _nftContract,
        bytes32 _hashedData,
        uint256 _tokenId,
        AssignedRights _rights,
        StatusType _status
    ) external;

    function getEntry(uint256 _tokenId, address _nftContract)
        external
        view
        returns (HDNFT memory);

    function getEntriesByContract(address _nftContract)
        external
        view
        returns (HDNFT[] memory);
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