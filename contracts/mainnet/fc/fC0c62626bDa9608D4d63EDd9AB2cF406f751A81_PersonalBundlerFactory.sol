// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./utils/Ownable.sol";

import "./PersonalBundler.sol";

/**
 * @title PersonalBundlerFactory
 * @author NFTfi
 * @dev
 */
contract PersonalBundlerFactory is Ownable {
    address public immutable personalBundlerImplementation;
    string public baseURI;

    mapping(address => bool) public personalBundlerExists;

    event PersonalBundlerCreated(address indexed instance, address indexed owner, address creator);

    /**
     * @param _admin admin address capable of setting URI
     * @param _customBaseURI - Base URI
     * @param _personalBundlerImplementation - deployed master copy of the personal bundler contract
     */
    constructor(
        address _admin,
        string memory _customBaseURI,
        address _personalBundlerImplementation
    ) Ownable(_admin) {
        baseURI = _customBaseURI;
        personalBundlerImplementation = _personalBundlerImplementation;
    }

    /**
     * @dev clones a new personal bundler contract
     *
     * @param _to - owner of the personal bundler
     */
    function createPersonalBundler(address _to) external returns (address) {
        address instance = Clones.clone(personalBundlerImplementation);
        personalBundlerExists[instance] = true;
        PersonalBundler(instance).initialize(owner(), _to, baseURI);
        emit PersonalBundlerCreated(instance, _to, msg.sender);
        return instance;
    }

    /**
     * @dev Sets baseURI.
     * @param _customBaseURI - Base URI
     */
    function setBaseURI(string memory _customBaseURI) external onlyOwner {
        baseURI = _customBaseURI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";

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
 *
 * Modified version from openzeppelin/contracts/access/Ownable.sol that allows to
 * initialize the owner using a parameter in the constructor
 */
abstract contract Ownable is Context {
    address private _owner;

    address private _ownerCandidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /**
     * @dev Requests transferring ownership of the contract to a new account (`_newOwnerCandidate`).
     * Can only be called by the current owner.
     */
    function requestTransferOwnership(address _newOwnerCandidate) public virtual onlyOwner {
        require(_newOwnerCandidate != address(0), "Ownable: new owner is the zero address");
        _ownerCandidate = _newOwnerCandidate;
    }

    function acceptTransferOwnership() public virtual {
        require(_ownerCandidate == _msgSender(), "Ownable: not owner candidate");
        _setOwner(_ownerCandidate);
        delete _ownerCandidate;
    }

    function cancelTransferOwnership() public virtual onlyOwner {
        delete _ownerCandidate;
    }

    function rejectTransferOwnership() public virtual {
        require(_ownerCandidate == _msgSender(), "Ownable: not owner candidate");
        delete _ownerCandidate;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Sets the owner.
     */
    function _setOwner(address _newOwner) internal {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./NftfiBundler.sol";

/**
 * @title PersonalBundler
 * @author NFTfi
 * @dev ERC998 Top-Down Composable Non-Fungible Token that supports ERC721 children.
 */
contract PersonalBundler is NftfiBundler, Initializable, IERC1155Receiver {
    using SafeERC20 for IERC20;

    uint8 public constant bundleId = 1;
    address public lastBundleOwner;

    event Initialized(address owner);

    /**
     * @dev only runs when the master copy is deplyoed, when cloned then initializer is ran
     * @param _admin admin address capable of setting URI-s and pausing
     * @param _permittedNfts permitted nft-s contract of the loan system
     * @param _airdropFlashLoan airdrop flashloan contract deplyoed alongside
     */
    constructor(
        address _admin,
        address _permittedNfts,
        address _airdropFlashLoan
    ) NftfiBundler(_admin, "", "", "", _permittedNfts, _airdropFlashLoan) {
        //original implementation rendering it unusable
        safeMint(_admin);
    }

    /** @dev function enforcing that the caller is the bundle token owner */
    function onlyBundleOwner() internal view {
        require(ownerOf(bundleId) == msg.sender, "Only bundle owner");
    }

    /**
     * @dev sets up initial parameters after cloning
     *
     * @param _admin admin address capable of setting URI-s and pausing
     * @param _owner of the personal bundler
     * @param _customBaseURI - Base URI
     */
    function initialize(
        address _admin,
        address _owner,
        string memory _customBaseURI
    ) external initializer nonReentrant {
        _setOwner(_admin);
        _setBaseURI(_customBaseURI);
        safeMint(_owner);
        emit Initialized(_owner);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     * have to override, because cloning doesn't work for it
     */
    function name() public view virtual override returns (string memory) {
        return "NFTFi Personal Bundle";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     * have to override, because cloning doesn't work for it
     */
    function symbol() public view virtual override returns (string memory) {
        return "PBNFI";
    }

    function safeMint(address _to) public override returns (uint256) {
        require(lastBundleOwner == address(0) || lastBundleOwner == msg.sender, "only last bundle owner");
        require(tokenCount == 0, "only 1 bundle");

        return super.safeMint(_to);
    }

    function burn() public {
        onlyBundleOwner();
        lastBundleOwner = msg.sender;
        require(totalChildContracts(bundleId) == 0, "bundle has to be empty");
        tokenCount -= 1;
        _burn(bundleId);
    }

    /**
     * @notice disabled here
     */
    function sendElementsToPersonalBundler(uint256, address) external virtual override {
        revert("already personal bundler");
    }

    /**
     * @dev Validates the data from a child transfer and receives it
     * @param _from The owner of the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     */
    function _validateAndReceiveChild(
        address _from,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) internal virtual override {
        //CHECK DISABLED require(_data.length > 0, "data must contain tokenId to transfer the child token to");
        // if no data: airdrop
        if (_data.length > 0) {
            // convert up to 32 bytes of _data to uint256, owner nft tokenId passed as uint in bytes
            uint256 tokenId = _parseTokenId(_data);
            // 1 is the only existing valid token id, so all other data is an airdrop
            if (tokenId == bundleId) {
                _receiveChild(_from, tokenId, _childContract, _childTokenId);
            }
        }
    }

    /**
     * @notice used by the owner account to be able to drain ERC721 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _tokenId - id token to be sent out
     * @param _receiver - receiver of the token
     */
    function drainERC721Airdrop(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external {
        onlyBundleOwner();
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(childTokenOwner[_tokenAddress][_tokenId] == 0, "token is in bundle");
        require(tokenContract.ownerOf(_tokenId) == address(this), "nft not owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC1155 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _tokenId - id token to be sent out
     * @param _receiver - receiver of the token
     */
    function drainERC1155Airdrop(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external {
        onlyBundleOwner();
        IERC1155 tokenContract = IERC1155(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this), _tokenId);
        require(amount > 0, "no nfts owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId, amount, "");
    }

    /**
     * @notice used by the owner account to be able to drain ERC20 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _receiver - receiver of the token
     */
    function drainERC20Airdrop(address _tokenAddress, address _receiver) external {
        onlyBundleOwner();
        IERC20 tokenContract = IERC20(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "no tokens owned");
        tokenContract.safeTransfer(_receiver, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, NftfiBundler) returns (bool) {
        return _interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     *  @dev Handles the receipt of a single ERC1155 token type. This function is called at the end of a
     * `safeTransferFrom` after the balance has been updated.
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if allowed
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     *  @dev Handles the receipt of a multiple ERC1155 token types. This function is called at the end of a
     * `safeBatchTransferFrom` after the balances have been updated.
     *  @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if allowed
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC998TopDown.sol";
import "./INftfiBundler.sol";
import "./IBundleBuilder.sol";
import "./IPermittedNFTs.sol";
import "./utils/Ownable.sol";
import "./airdrop/AirdropFlashLoan.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NftfiBundler
 * @author NFTfi
 * @dev ERC998 Top-Down Composable Non-Fungible Token that supports ERC721 children.
 */
contract NftfiBundler is ERC998TopDown, IBundleBuilder {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    address public immutable permittedNfts;
    address public immutable airdropFlashLoan;

    string public baseURI;

    /**
     * @dev Stores name and symbol
     *
     * @param _admin - Initial admin of this contract.
     * @param _name name of the token contract
     * @param _symbol symbol of the token contract
     */
    constructor(
        address _admin,
        string memory _name,
        string memory _symbol,
        string memory _customBaseURI,
        address _permittedNfts,
        address _airdropFlashLoan
    ) ERC721(_name, _symbol) ERC998TopDown(_admin) {
        permittedNfts = _permittedNfts;
        airdropFlashLoan = _airdropFlashLoan;
        _setBaseURI(_customBaseURI);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IERC721Receiver).interfaceId ||
            _interfaceId == type(INftfiBundler).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Tells if an asset is permitted or not
     * @param _asset address of the asset
     * @return true if permitted, false otherwise
     */
    function permittedAsset(address _asset) public view returns (bool) {
        IPermittedNFTs permittedNFTs = IPermittedNFTs(permittedNfts);
        return permittedNFTs.getNFTPermit(_asset) > 0;
    }

    /**
     * @dev used to build a bundle from the BundleElements struct,
     * returns the id of the created bundle
     *
     * @param _bundleElements - the lists of erc721 tokens that are to be bundled
     */
    function buildBundle(BundleElementERC721[] memory _bundleElements) external override returns (uint256) {
        uint256 tokenId = safeMint(msg.sender);
        _addBundleElements(tokenId, _bundleElements);
        return tokenId;
    }

    /**
     * @dev Adds a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to add the bundle elements to.
     * @param _bundleElements The array of BundleElementERC721 objects to add.
     */
    function addBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) external {
        _addBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Removes a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to remove the bundle elements from.
     * @param _bundleElements The array of BundleElementERC721 objects to remove.
     */
    function removeBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) external {
        _removeBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Adds and removes a set of BundleElementERC721 objects from the specified token ID.
     *
     * @param _tokenId The ID of the token to add and remove the bundle elements from.
     * @param _toAdd The array of BundleElementERC721 objects to add.
     * @param _toRemove The array of BundleElementERC721 objects to remove.
     */
    function addAndRemoveBundleElements(
        uint256 _tokenId,
        BundleElementERC721[] memory _toAdd,
        BundleElementERC721[] memory _toRemove
    ) external {
        _addBundleElements(_tokenId, _toAdd);
        _removeBundleElements(_tokenId, _toRemove);
    }

    /**
     * @notice Remove all the children from the bundle
     * @dev This method may run out of gas if the list of children is too big. In that case, children can be removed
     *      individually.
     * @param _tokenId the id of the bundle
     * @param _receiver address of the receiver of the children
     */
    function decomposeBundle(uint256 _tokenId, address _receiver) external override {
        _validateReceiver(_receiver);
        _validateTransferSender(_tokenId);

        // In each iteration all contracts children are removed, so eventually all contracts are removed
        while (childContracts[_tokenId].length() > 0) {
            address childContract = childContracts[_tokenId].at(0);

            // In each iteration a child is removed, so eventually all contracts children are removed
            while (childTokens[_tokenId][childContract].length() > 0) {
                uint256 childId = childTokens[_tokenId][childContract].at(0);

                _removeChild(_tokenId, childContract, childId);

                try IERC721(childContract).safeTransferFrom(address(this), _receiver, childId) {
                    // solhint-disable-previous-line no-empty-blocks
                } catch {
                    _oldNFTsTransfer(_receiver, childContract, childId);
                }
                emit TransferChild(_tokenId, _receiver, childContract, childId);
            }
        }
    }

    /**
     * @notice Remove all the children from the bundle and send to personla bundler.
     * If bundle contains a legacy ERC721 element, this will not work.
     * @dev This method may run out of gas if the list of children is too big. In that case, children can be removed
     *      individually.
     * @param _tokenId the id of the bundle
     * @param _personalBundler address of the receiver of the children
     */
    function sendElementsToPersonalBundler(uint256 _tokenId, address _personalBundler) external virtual {
        _validateReceiver(_personalBundler);
        _validateTransferSender(_tokenId);
        require(_personalBundler != address(this), "cannot send to self");
        require(
            IERC165(_personalBundler).supportsInterface(type(IERC998ERC721TopDown).interfaceId),
            "has to implement IERC998ERC721TopDown"
        );
        uint256 personalBundleId = 1;
        //make sure sendeer owns personal bundler token
        require(IERC721(_personalBundler).ownerOf(personalBundleId) == msg.sender, "has to own personal bundle token");

        // In each iteration all contracts children are removed, so eventually all contracts are removed
        while (childContracts[_tokenId].length() > 0) {
            address childContract = childContracts[_tokenId].at(0);

            // In each iteration a child is removed, so eventually all contracts children are removed
            while (childTokens[_tokenId][childContract].length() > 0) {
                uint256 childId = childTokens[_tokenId][childContract].at(0);

                _removeChild(_tokenId, childContract, childId);

                try
                    IERC721(childContract).safeTransferFrom(
                        address(this),
                        _personalBundler,
                        childId,
                        abi.encodePacked(personalBundleId)
                    )
                {
                    // solhint-disable-previous-line no-empty-blocks
                } catch {
                    revert("only safe transfer");
                }
                emit TransferChild(_tokenId, _personalBundler, childContract, childId);
            }
        }
    }

    /**
     * @dev Internal function to add a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to add the bundle elements to.
     * @param _bundleElements The array of BundleElementERC721 objects to add.
     */
    function _addBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) internal {
        require(_bundleElements.length > 0, "bundle is empty");
        uint256 elementNumber = _bundleElements.length;
        for (uint256 i; i != elementNumber; ++i) {
            require(permittedAsset(_bundleElements[i].tokenContract), "erc721 not permitted");
            if (_bundleElements[i].safeTransferable) {
                uint256 nuberOfIds = _bundleElements[i].ids.length;
                for (uint256 j; j != nuberOfIds; ++j) {
                    IERC721(_bundleElements[i].tokenContract).safeTransferFrom(
                        msg.sender,
                        address(this),
                        _bundleElements[i].ids[j],
                        abi.encodePacked(_tokenId)
                    );
                }
            } else {
                uint256 nuberOfIds = _bundleElements[i].ids.length;
                for (uint256 j; j != nuberOfIds; ++j) {
                    getChild(msg.sender, _tokenId, _bundleElements[i].tokenContract, _bundleElements[i].ids[j]);
                }
            }
        }

        emit AddBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Internal function to remove a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to remove the bundle elements from.
     * @param _bundleElements The array of BundleElementERC721 objects to remove.
     */
    function _removeBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) internal {
        require(_bundleElements.length > 0, "bundle is empty");
        uint256 elementNumber = _bundleElements.length;
        for (uint256 i; i != elementNumber; ++i) {
            address erc721Contract = _bundleElements[i].tokenContract;
            uint256 nuberOfIds = _bundleElements[i].ids.length;
            for (uint256 j; j != nuberOfIds; ++j) {
                uint256 childId = _bundleElements[i].ids[j];
                _validateChildTransfer(_tokenId, erc721Contract, childId);
                _removeChild(_tokenId, erc721Contract, childId);
                if (_bundleElements[i].safeTransferable) {
                    IERC721(erc721Contract).safeTransferFrom(address(this), msg.sender, childId);
                } else {
                    _oldNFTsTransfer(msg.sender, erc721Contract, childId);
                }
                emit TransferChild(_tokenId, msg.sender, erc721Contract, childId);
            }
        }

        emit RemoveBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Update the state to receive a ERC721 child
     * Overrides the implementation to check if the asset is permitted
     * @param _from The owner of the child token
     * @param _tokenId The token receiving the child
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     */
    function _receiveChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual override {
        require(permittedAsset(_childContract), "erc721 not permitted");
        super._receiveChild(_from, _tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Override validation if it is a transfer from the airdropFlashLoan contract giving back the flashloan.
     * Validates the data from a child transfer and receives it otherwise
     * @param _from The owner of the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     */
    function _validateAndReceiveChild(
        address _from,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) internal virtual override {
        if (_from == airdropFlashLoan) {
            return;
        } else {
            super._validateAndReceiveChild(_from, _childContract, _childTokenId, _data);
        }
    }

    /**
     * @notice this function initiates a flashloan to pull an airdrop from a tartget contract
     *
     * @param _nftContract - contract address of the target nft of the drop
     * @param _nftId - id of the target nft of the drop
     * @param _target - address of the airdropping contract
     * @param _data - function selector to be called on the airdropping contract
     * @param _nftAirdrop - address of the used claiming nft in the drop
     * @param _nftAirdropId - id of the used claiming nft in the drop
     * @param _is1155 -
     * @param _nftAirdropAmount - amount in case of 1155
     */
    function pullAirdrop(
        address _nftContract,
        uint256 _nftId,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        address _beneficiary
    ) external {
        uint256 tokenId = childTokenOwner[_nftContract][_nftId];
        address rootOwner = address(uint160(uint256(rootOwnerOf(tokenId))));
        require(rootOwner == msg.sender, "pullAirdrop msg.sender not eligible");

        IERC721(_nftContract).safeTransferFrom(address(this), airdropFlashLoan, _nftId);

        AirdropFlashLoan(airdropFlashLoan).pullAirdrop(
            _nftContract,
            _nftId,
            _target,
            _data,
            _nftAirdrop,
            _nftAirdropId,
            _is1155,
            _nftAirdropAmount,
            _beneficiary
        );

        //take back collateral
        IERC721(_nftContract).safeTransferFrom(airdropFlashLoan, address(this), _nftId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC721 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _tokenId - id token to be sent out
     * @param _receiver - receiver of the token
     */
    function rescueERC721(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external onlyOwner {
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(childTokenOwner[_tokenAddress][_tokenId] == 0, "token is in bundle");
        require(tokenContract.ownerOf(_tokenId) == address(this), "nft not owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC20 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _receiver - receiver of the token
     */
    function rescueERC20(address _tokenAddress, address _receiver) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "no tokens owned");
        tokenContract.safeTransfer(_receiver, amount);
    }

    /**
     * @dev Sets baseURI.
     * @param _customBaseURI - Base URI
     */
    function setBaseURI(string memory _customBaseURI) external onlyOwner {
        _setBaseURI(_customBaseURI);
    }

    /**
     * @dev Sets baseURI.
     */
    function _setBaseURI(string memory _customBaseURI) internal virtual {
        baseURI = bytes(_customBaseURI).length > 0
            ? string(abi.encodePacked(_customBaseURI, _getChainID().toString(), "/"))
            : "";
    }

    /** @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev This function gets the current chain ID.
     */
    function _getChainID() internal view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./utils/Ownable.sol";
import "./IERC998ERC721TopDown.sol";
import "./IERC998ERC721TopDownEnumerable.sol";

/**
 * @title ERC998TopDown
 * @author NFTfi
 * @dev ERC998ERC721 Top-Down Composable Non-Fungible Token.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-998.md
 * This implementation does not support children to be nested bundles, erc20 nor bottom-up
 */
abstract contract ERC998TopDown is
    ERC721Enumerable,
    IERC998ERC721TopDown,
    IERC998ERC721TopDownEnumerable,
    ReentrancyGuard,
    Ownable,
    Pausable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // return this.rootOwnerOf.selector ^ this.rootOwnerOfChild.selector ^
    //   this.tokenOwnerOf.selector ^ this.ownerOfChild.selector;
    bytes32 public constant ERC998_MAGIC_VALUE = 0xcd740db500000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant ERC998_MAGIC_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    uint256 public tokenCount = 0;

    // tokenId => child contract
    mapping(uint256 => EnumerableSet.AddressSet) internal childContracts;

    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal childTokens;

    // child address => childId => tokenId
    // this is used for ERC721 type tokens
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

    /**
     * @dev Stores the admin
     *
     * @param _admin address capable of pausing
     */
    constructor(address _admin) Ownable(_admin) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Tells whether the ERC721 type child exists or not
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return True if the child exists, false otherwise
     */
    function childExists(address _childContract, uint256 _childTokenId) external view virtual returns (bool) {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        return tokenId != 0;
    }

    /**
     * @notice Get the total number of child contracts with tokens that are owned by _tokenId
     * @param _tokenId The parent token of child tokens in child contracts
     * @return uint256 The total number of child contracts with tokens owned by _tokenId
     */
    function totalChildContracts(uint256 _tokenId) public view virtual override returns (uint256) {
        return childContracts[_tokenId].length();
    }

    /**
     * @notice Get child contract by tokenId and index
     * @param _tokenId The parent token of child tokens in child contract
     * @param _index The index position of the child contract
     * @return childContract The contract found at the _tokenId and index
     */
    function childContractByIndex(uint256 _tokenId, uint256 _index)
        external
        view
        virtual
        override
        returns (address childContract)
    {
        return childContracts[_tokenId].at(_index);
    }

    /**
     * @notice Get the total number of child tokens owned by tokenId that exist in a child contract
     * @param _tokenId The parent token of child tokens
     * @param _childContract The child contract containing the child tokens
     * @return uint256 The total number of child tokens found in child contract that are owned by _tokenId
     */
    function totalChildTokens(uint256 _tokenId, address _childContract) external view override returns (uint256) {
        return childTokens[_tokenId][_childContract].length();
    }

    /**
     * @notice Get child token owned by _tokenId, in child contract, at index position
     * @param _tokenId The parent token of the child token
     * @param _childContract The child contract of the child token
     * @param _index The index position of the child token
     * @return childTokenId The child tokenId for the parent token, child token and index
     */
    function childTokenByIndex(
        uint256 _tokenId,
        address _childContract,
        uint256 _index
    ) external view virtual override returns (uint256 childTokenId) {
        return childTokens[_tokenId][_childContract].at(_index);
    }

    /**
     * @notice Get the parent tokenId and its owner of a ERC721 child token
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return parentTokenOwner The parent address of the parent token and ERC998 magic value
     * @return parentTokenId The parent tokenId of _childTokenId
     */
    function ownerOfChild(address _childContract, uint256 _childTokenId)
        external
        view
        virtual
        override
        returns (bytes32 parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "child token does not exist");
        address parentTokenOwnerAddress = ownerOf(parentTokenId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            parentTokenOwner := or(ERC998_MAGIC_VALUE, parentTokenOwnerAddress)
        }
    }

    /**
     * @notice Get the root owner of tokenId
     * @param _tokenId The token to query for a root owner address
     * @return rootOwner The root owner at the top of tree of tokens and ERC998 magic value.
     */
    function rootOwnerOf(uint256 _tokenId) public view virtual override returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    /**
     * @notice Get the root owner of a child token
     * @dev Returns the owner at the top of the tree of composables
     * Use Cases handled:
     * - Case 1: Token owner is this contract and token.
     * - Case 2: Token owner is other external top-down composable
     * - Case 3: Token owner is other contract
     * - Case 4: Token owner is user
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return rootOwner The root owner at the top of tree of tokens and ERC998 magic value
     */
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId)
        public
        view
        virtual
        override
        returns (bytes32 rootOwner)
    {
        address rootOwnerAddress;
        if (_childContract != address(0)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(_childContract, _childTokenId);
        } else {
            rootOwnerAddress = ownerOf(_childTokenId);
        }

        if (rootOwnerAddress.isContract()) {
            try IERC998ERC721TopDown(rootOwnerAddress).rootOwnerOfChild(address(this), _childTokenId) returns (
                bytes32 returnedRootOwner
            ) {
                // Case 2: Token owner is other external top-down composable
                if (returnedRootOwner & ERC998_MAGIC_MASK == ERC998_MAGIC_VALUE) {
                    return returnedRootOwner;
                }
            } catch {
                // solhint-disable-previous-line no-empty-blocks
            }
        }

        // Case 3: Token owner is other contract
        // Or
        // Case 4: Token owner is user
        // solhint-disable-next-line no-inline-assembly
        assembly {
            rootOwner := or(ERC998_MAGIC_VALUE, rootOwnerAddress)
        }
        return rootOwner;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * The interface id 0x1efdf36a is added. The spec claims it to be the interface id of IERC998ERC721TopDown.
     * But it is not.
     * It is added anyway in case some contract checks it being compliant with the spec.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return
            _interfaceId == type(IERC998ERC721TopDown).interfaceId ||
            _interfaceId == type(IERC998ERC721TopDownEnumerable).interfaceId ||
            _interfaceId == 0x1efdf36a ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Mints a new bundle
     * @param _to The address that owns the new bundle
     * @return The id of the new bundle
     */
    function safeMint(address _to) public virtual whenNotPaused returns (uint256) {
        uint256 id = ++tokenCount;
        _safeMint(_to, id);

        return id;
    }

    /**
     * @notice Transfer child token from top-down composable to address
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external virtual override nonReentrant {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        IERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    /**
     * @notice Transfer child token from top-down composable to address or other top-down composable
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     * @param _data Additional data with no specified format
     */
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external virtual override nonReentrant {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        if (_to == address(this)) {
            _validateAndReceiveChild(msg.sender, _childContract, _childTokenId, _data);
        } else {
            IERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId, _data);
            emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
        }
    }

    /**
     * @dev Transfer child token from top-down composable to address
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external virtual override nonReentrant {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        _oldNFTsTransfer(_to, _childContract, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    /**
     * @notice NOT SUPPORTED
     * Intended to transfer bottom-up composable child token from top-down composable to other ERC721 token.
     */
    function transferChildToParent(
        uint256,
        address,
        uint256,
        address,
        uint256,
        bytes memory
    ) external virtual override {
        revert("BOTTOM_UP_CHILD_NOT_SUPPORTED");
    }

    /**
     * @notice Transfer a child token from an ERC721 contract to a composable. Used for old tokens that does not
     * have a safeTransferFrom method like cryptokitties
     * @dev This contract has to be approved first in _childContract
     * @param _from The address that owns the child token.
     * @param _tokenId The token that becomes the parent owner
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the child token
     */
    function getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) public virtual override whenNotPaused nonReentrant {
        require(_from == msg.sender, "_from should be msg.sender");
        _receiveChild(_from, _tokenId, _childContract, _childTokenId);
        IERC721(_childContract).transferFrom(_from, address(this), _childTokenId);
    }

    /**
     * @notice A token receives a child token
     * param The address that caused the transfer
     * @param _from The owner of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     * @return the selector of this method
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _childTokenId,
        bytes calldata _data
    ) external virtual override whenNotPaused nonReentrant returns (bytes4) {
        _validateAndReceiveChild(_from, msg.sender, _childTokenId, _data);
        return this.onERC721Received.selector;
    }

    /**
     * @dev ERC721 implementation hook that is called before any token transfer. Prevents nested bundles
     * @param _from address of the current owner of the token
     * @param _to destination address
     * @param _tokenId id of the token to transfer
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(_to != address(this), "nested bundles not allowed");
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * @dev Validates the child transfer parameters and remove the child from the bundle
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function _transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        _validateReceiver(_to);
        _validateChildTransfer(_fromTokenId, _childContract, _childTokenId);
        _removeChild(_fromTokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Validates the child transfer parameters
     * @param _fromTokenId The owning token to transfer from
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function _validateChildTransfer(
        uint256 _fromTokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId != 0, "_transferChild _childContract _childTokenId not found");
        require(tokenId == _fromTokenId, "ComposableTopDown: _transferChild wrong tokenId found");
        _validateTransferSender(tokenId);
    }

    /**
     * @dev Validates the receiver of a child transfer
     * @param _to The address that receives the child token
     */
    function _validateReceiver(address _to) internal virtual {
        require(_to != address(0), "child transfer to zero address");
    }

    /**
     * @dev Updates the state to remove a child
     * @param _tokenId The owning token to transfer from
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function _removeChild(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        // remove child token
        childTokens[_tokenId][_childContract].remove(_childTokenId);
        delete childTokenOwner[_childContract][_childTokenId];

        // remove contract
        if (childTokens[_tokenId][_childContract].length() == 0) {
            childContracts[_tokenId].remove(_childContract);
        }
    }

    /**
     * @dev Validates the data from a child transfer and receives it
     * @param _from The owner of the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     */
    function _validateAndReceiveChild(
        address _from,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) internal virtual {
        require(_data.length > 0, "data must contain tokenId to transfer the child token to");
        // convert up to 32 bytes of _data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId = _parseTokenId(_data);
        _receiveChild(_from, tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Update the state to receive a child
     * @param _from The owner of the child token
     * @param _tokenId The token receiving the child
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     */
    function _receiveChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        require(_exists(_tokenId), "bundle tokenId does not exist");
        uint256 childTokensLength = childTokens[_tokenId][_childContract].length();
        if (childTokensLength == 0) {
            childContracts[_tokenId].add(_childContract);
        }
        childTokens[_tokenId][_childContract].add(_childTokenId);
        childTokenOwner[_childContract][_childTokenId] = _tokenId;
        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Returns the owner of a child
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return parentTokenOwner The parent address of the parent token and ERC998 magic value
     * @return parentTokenId The parent tokenId of _childTokenId
     */
    function _ownerOfChild(address _childContract, uint256 _childTokenId)
        internal
        view
        virtual
        returns (address parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "child token does not exist");
        return (ownerOf(parentTokenId), parentTokenId);
    }

    /**
     * @dev Convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     * @return tokenId the token Id encoded in the data
     */
    function _parseTokenId(bytes memory _data) internal pure virtual returns (uint256 tokenId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenId := mload(add(_data, 0x20))
        }
    }

    /**
     * @dev Transfers the NFT using method compatible with old token contracts
     * @param _to address of the receiver of the children
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     */
    function _oldNFTsTransfer(
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) internal {
        // This is here to be compatible with cryptokitties and other old contracts that require being owner and
        // approved before transferring.
        // Does not work with current standard which does not allow approving self, so we must let it fail in that case.
        try IERC721(_childContract).approve(address(this), _childTokenId) {
            // solhint-disable-previous-line no-empty-blocks
        } catch {
            // solhint-disable-previous-line no-empty-blocks
        }

        IERC721(_childContract).transferFrom(address(this), _to, _childTokenId);
    }

    /**
     * @notice Validates that the sender is authorized to perform a child transfer
     * @param _fromTokenId The owning token to transfer from
     */
    function _validateTransferSender(uint256 _fromTokenId) internal virtual {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_fromTokenId))));
        require(
            rootOwner == msg.sender ||
                getApproved(_fromTokenId) == msg.sender ||
                isApprovedForAll(rootOwner, msg.sender),
            "transferChild msg.sender not eligible"
        );
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Only the owner can call this method.
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Only the owner can call this method.
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INftfiBundler is IERC721 {
    function safeMint(address _to) external returns (uint256);

    function decomposeBundle(uint256 _tokenId, address _receiver) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IBundleBuilder {
    /**
     * @notice data of a erc721 bundle element
     *
     * @param tokenContract - address of the token contract
     * @param id - id of the token
     * @param safeTransferable - wether the implementing token contract has a safeTransfer function or not
     */
    struct BundleElementERC721 {
        address tokenContract;
        uint256[] ids;
        bool safeTransferable;
    }

    /**
     * @notice used to build a bundle from the BundleElements struct,
     * returns the id of the created bundle
     *
     * @param _bundleElements - the lists of erc721 tokens that are to be bundled
     */
    function buildBundle(BundleElementERC721[] memory _bundleElements) external returns (uint256);

    /**
     * @notice Remove all the children from the bundle
     * @dev This method may run out of gas if the list of children is too big. In that case, children can be removed
     *      individually or in smaller batches.
     * @param _tokenId the id of the bundle
     * @param _receiver address of the receiver of the children
     */
    function decomposeBundle(uint256 _tokenId, address _receiver) external;

    event AddBundleElements(uint256 indexed _tokenId, BundleElementERC721[] _bundleElements);
    event RemoveBundleElements(uint256 indexed _tokenId, BundleElementERC721[] _bundleElements);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IPermittedNFTs {
    function getNFTPermit(address _nftContract) external view returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AirdropFlashLoan
 * @author NFTfi
 * @dev
 */
contract AirdropFlashLoan is ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    /**
     * @notice this function initiates a flashloan to pull an airdrop from a tartget contract
     *
     * @param _nftContract - contract address of the target nft of the drop
     * @param _nftId - id of the target nft of the drop
     * @param _target - address of the airdropping contract
     * @param _data - function selector to be called on the airdropping contract
     * @param _nftAirdrop - address of the used claiming nft in the drop
     * @param _nftAirdropId - id of the used claiming nft in the drop
     * @param _is1155 -
     * @param _nftAirdropAmount - amount in case of 1155
     * @param _beneficiary - address receiving the drop
     */
    function pullAirdrop(
        address _nftContract,
        uint256 _nftId,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        address _beneficiary
    ) external nonReentrant {
        // assumes that the collateral nft has been transferreded to this contract before calling this function
        _target.functionCall(_data);

        // return the collateral
        IERC721(_nftContract).approve(msg.sender, _nftId);

        // in case that arbitray function from _target does not send the airdrop to a specified address
        if (_nftAirdrop != address(0) && _beneficiary != address(0)) {
            // send the airdrop to the beneficiary
            if (_is1155) {
                IERC1155(_nftAirdrop).safeTransferFrom(
                    address(this),
                    _beneficiary,
                    _nftAirdropId,
                    _nftAirdropAmount,
                    "0x"
                );
            } else {
                IERC721(_nftAirdrop).safeTransferFrom(address(this), _beneficiary, _nftAirdropId);
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return _interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC998ERC721TopDown {
    event ReceivedChild(
        address indexed _from,
        uint256 indexed _tokenId,
        address indexed _childContract,
        uint256 _childTokenId
    );
    event TransferChild(
        uint256 indexed tokenId,
        address indexed _to,
        address indexed _childContract,
        uint256 _childTokenId
    );

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _childTokenId,
        bytes calldata _data
    ) external returns (bytes4);

    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external;

    function transferChildToParent(
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external;

    // getChild function enables older contracts like cryptokitties to be transferred into a composable
    // The _childContract must approve this contract. Then getChild can be called.
    function getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) external;

    function rootOwnerOf(uint256 _tokenId) external view returns (bytes32 rootOwner);

    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 rootOwner);

    function ownerOfChild(address _childContract, uint256 _childTokenId)
        external
        view
        returns (bytes32 parentTokenOwner, uint256 parentTokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC998ERC721TopDownEnumerable {
    function totalChildContracts(uint256 _tokenId) external view returns (uint256);

    function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract);

    function totalChildTokens(uint256 _tokenId, address _childContract) external view returns (uint256);

    function childTokenByIndex(
        uint256 _tokenId,
        address _childContract,
        uint256 _index
    ) external view returns (uint256 childTokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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