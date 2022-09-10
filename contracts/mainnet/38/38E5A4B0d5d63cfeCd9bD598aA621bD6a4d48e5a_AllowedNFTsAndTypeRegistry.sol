// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IAllowedNFTs.sol";
import "../interfaces/INftTypeRegistry.sol";
import "../interfaces/IDispatcher.sol";
import "../utils/Ownable.sol";
import "../utils/KeysMapping.sol";

contract AllowedNFTsAndTypeRegistry is Ownable, IAllowedNFTs {
    IDispatcher public hub;
    mapping(bytes32 => address) private nftTypes;

    mapping(address => bytes32) private nftPermits;

    event TypeUpdated(bytes32 indexed nftType, address indexed nftWrapper);

    event NFTPermit(address indexed nftContract, bytes32 indexed nftType);

    modifier onlyOwnerOrAirdropFactory(string memory _nftType) {
        if (
            KeysMapping.keyToId(_nftType) ==
            KeysMapping.keyToId(KeysMapping.AIRDROP_WRAPPER_STRING)
        ) {
            require(hub.getContract(KeysMapping.AIRDROP_FACTORY) == _msgSender(), "caller is not AirdropFactory");
        } else {
            require(owner() == _msgSender(), "caller is not owner");
        }
        _;
    }

    constructor(
        address _admin,
        address _dispatcher,
        string[] memory _definedNftTypes,
        address[] memory _definedNftWrappers,
        address[] memory _permittedNftContracts,
        string[] memory _permittedNftTypes
    ) Ownable(_admin) {
        hub = IDispatcher(_dispatcher);
        _setNftTypes(_definedNftTypes, _definedNftWrappers);
        _setNFTPermits(_permittedNftContracts, _permittedNftTypes);
    }

    function setNFTPermit(address _nftContract, string memory _nftType)
        external
        override
        onlyOwnerOrAirdropFactory(_nftType)
    {
        _setNFTPermit(_nftContract, _nftType);
    }

    function setNFTPermits(address[] memory _nftContracts, string[] memory _nftTypes) external onlyOwner {
        _setNFTPermits(_nftContracts, _nftTypes);
    }

    function getNFTPermit(address _nftContract) external view override returns (bytes32) {
        return nftPermits[_nftContract];
    }

    function getNFTWrapper(address _nftContract) external view override returns (address) {
        bytes32 nftType = nftPermits[_nftContract];
        return getNftTypeWrapper(nftType);
    }

    function setNftType(string memory _nftType, address _nftWrapper) external onlyOwner {
        _setNftType(_nftType, _nftWrapper);
    }

    function setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) external onlyOwner {
        _setNftTypes(_nftTypes, _nftWrappers);
    }

    function getNftTypeWrapper(bytes32 _nftType) public view returns (address) {
        return nftTypes[_nftType];
    }

    function _setNftType(string memory _nftType, address _nftWrapper) internal {
        require(bytes(_nftType).length != 0, "nftType is empty");
        bytes32 nftTypeKey = KeysMapping.keyToId(_nftType);

        nftTypes[nftTypeKey] = _nftWrapper;

        emit TypeUpdated(nftTypeKey, _nftWrapper);
    }

    function _setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) internal {
        require(_nftTypes.length == _nftWrappers.length, "setNftTypes function information arity mismatch");

        for (uint256 i = 0; i < _nftWrappers.length; i++) {
            _setNftType(_nftTypes[i], _nftWrappers[i]);
        }
    }

    function _setNFTPermit(address _nftContract, string memory _nftType) internal {
        require(_nftContract != address(0), "nftContract is zero address");
        bytes32 nftTypeKey = KeysMapping.keyToId(_nftType);

        if (nftTypeKey != 0) {
            require(getNftTypeWrapper(nftTypeKey) != address(0), "NFT type not registered");
        }

        require(
            nftPermits[_nftContract] != KeysMapping.keyToId(KeysMapping.AIRDROP_WRAPPER_STRING),
            "AirdropWrapper can't be modified"
        );
        nftPermits[_nftContract] = nftTypeKey;
        emit NFTPermit(_nftContract, nftTypeKey);
    }

    function _setNFTPermits(address[] memory _nftContracts, string[] memory _nftTypes) internal {
        require(_nftContracts.length == _nftTypes.length, "setNFTPermits function information arity mismatch");

        for (uint256 i = 0; i < _nftContracts.length; i++) {
            _setNFTPermit(_nftContracts[i], _nftTypes[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAllowedNFTs {
    function setNFTPermit(address _nftContract, string memory _nftType) external;

    function getNFTPermit(address _nftContract) external view returns (bytes32);

    function getNFTWrapper(address _nftContract) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface INftTypeRegistry {
    function setNftType(bytes32 _nftType, address _nftWrapper) external;

    function getNftTypeWrapper(bytes32 _nftType) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IDispatcher {
    function setContract(string calldata _contractKey, address _contractAddress) external;

    function getContract(bytes32 _contractKey) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(_newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _setOwner(address _newOwner) private {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library KeysMapping {
    bytes32 public constant PERMITTED_ERC20S = bytes32("PERMITTED_ERC20S");
    bytes32 public constant PERMITTED_NFTS = bytes32("PERMITTED_NFTS");
    bytes32 public constant PERMITTED_PARTNERS = bytes32("PERMITTED_PARTNERS");
    bytes32 public constant NFT_TYPE_REGISTRY = bytes32("NFT_TYPE_REGISTRY");
    bytes32 public constant LOAN_REGISTRY = bytes32("LOAN_REGISTRY");
    bytes32 public constant PERMITTED_SNFT_RECEIVER = bytes32("PERMITTED_SNFT_RECEIVER");
    bytes32 public constant PERMITTED_BUNDLE_ERC20S = bytes32("PERMITTED_BUNDLE_ERC20S");
    bytes32 public constant PERMITTED_AIRDROPS = bytes32("PERMITTED_AIRDROPS");
    bytes32 public constant AIRDROP_RECEIVER = bytes32("AIRDROP_RECEIVER");
    bytes32 public constant AIRDROP_FACTORY = bytes32("AIRDROP_FACTORY");
    bytes32 public constant AIRDROP_FLASH_LOAN = bytes32("AIRDROP_FLASH_LOAN");
    bytes32 public constant LIQUIDOTS_BUNDLER = bytes32("LIQUIDOTS_BUNDLER");

    string public constant AIRDROP_WRAPPER_STRING = "AirdropWrapper";

    function keyToId(string memory _key) external pure returns (bytes32 id) {
        require(bytes(_key).length <= 32, "invalid key");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := mload(add(_key, 32))
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