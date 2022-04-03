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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@rari-capital/solmate/src/tokens/ERC1155.sol";

contract ERC1155Contract is ERC1155, ReentrancyGuard, Ownable {

    struct InitialParameters {
        uint256 id;
        uint256 launchpassId;
        string name;
        string symbol;
        string uri;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        address payable multisigAddress;
    }

    struct TokenParameters {
        bytes32 merkleRoot;
        string uri;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool saleIsActive;
        bool supplyLock;
        address creator;
        uint256 totalSupply;
    }

    mapping(uint256 => TokenParameters) public tokenParameters;
    mapping (uint256 => mapping(address => uint256)) public hasMinted;
    address payable public multisigAddress;
    address payable public wentMintAddress;
    uint8 public wenmintShare;
    uint256 public launchpassId;
    string public name;
    string public symbol;

    modifier onlyMultisig() {
        require(msg.sender == multisigAddress, "Only multisig wallet can perfrom this action");
        _;
    }

    constructor(
        address payable _wentMintAddress,
        uint8 _wenmintShare,
        address _owner,
        InitialParameters memory initialParameters
      ) ERC1155() {
        name = initialParameters.name;
        symbol = initialParameters.symbol;
        uint256 _id = initialParameters.id;
        launchpassId = initialParameters.launchpassId;
        tokenParameters[_id].creator = msg.sender;
        tokenParameters[_id].uri = initialParameters.uri;
        tokenParameters[_id].maxSupply = initialParameters.maxSupply;
        tokenParameters[_id].maxPerWallet = initialParameters.maxPerWallet;
        tokenParameters[_id].maxPerTransaction = initialParameters.maxPerTransaction;
        tokenParameters[_id].preSalePrice = initialParameters.preSalePrice;
        tokenParameters[_id].pubSalePrice = initialParameters.pubSalePrice;
        tokenParameters[_id].preSaleIsActive = false;
        tokenParameters[_id].saleIsActive = false;
        tokenParameters[_id].supplyLock = false;
        tokenParameters[_id].totalSupply = 0;
        multisigAddress = initialParameters.multisigAddress;
        wenmintShare = _wenmintShare;
        wentMintAddress = _wentMintAddress;
        transferOwnership(_owner);
    }

    function uri(
        uint256 _id
    ) override public view returns (string memory) {
        require(tokenParameters[_id].creator != address(0), "Token does not exists");
        return tokenParameters[_id].uri;
    }

    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenParameters[_id].totalSupply;
    }

    function setMaxSupply(uint256 _id, uint24 _supply) public onlyOwner {
        require(!tokenParameters[_id].supplyLock, "Supply is locked.");
       tokenParameters[_id].maxSupply = _supply;
    }

    function lockSupply(uint256 _id) public onlyOwner {
        tokenParameters[_id].supplyLock = true;
    }

    function setPreSalePrice(uint256 _id, uint72 _price) public onlyOwner {
        tokenParameters[_id].preSalePrice = _price;
    }

    function setPublicSalePrice(uint256 _id, uint72 _price) public onlyOwner {
        tokenParameters[_id].pubSalePrice = _price;
    }

    function setMaxPerWallet(uint256 _id, uint24 _quantity) public onlyOwner {
        tokenParameters[_id].maxPerWallet = _quantity;
    }

    function setMaxPerTransaction(uint256 _id, uint24 _quantity) public onlyOwner {
        tokenParameters[_id].maxPerTransaction = _quantity;
    }

    function setRoot(uint256 _id, bytes32 _root) public onlyOwner {
        tokenParameters[_id].merkleRoot = _root;
    }

    function setPubSaleState(uint256 _id, bool _isActive) public onlyOwner {
        tokenParameters[_id].saleIsActive = _isActive;
    }

    function setPreSaleState(uint256 _id, bool _isActive) public onlyOwner {
        require(tokenParameters[_id].merkleRoot != "", "Merkle root is undefined.");
        tokenParameters[_id].preSaleIsActive = _isActive;
    }

    function verify(uint256 _id, bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;
        for (uint i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];
          if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }
        return computedHash == tokenParameters[_id].merkleRoot;
    }

    function create(
        uint256 _id,
        TokenParameters memory initialParameters
    ) public onlyOwner {
        require(tokenParameters[_id].creator == address(0), "token _id already exists");
        tokenParameters[_id].creator = msg.sender;
        tokenParameters[_id].maxSupply = initialParameters.maxSupply;
        tokenParameters[_id].maxPerWallet = initialParameters.maxPerWallet;
        tokenParameters[_id].maxPerTransaction = initialParameters.maxPerTransaction;
        tokenParameters[_id].preSalePrice = initialParameters.preSalePrice;
        tokenParameters[_id].pubSalePrice = initialParameters.pubSalePrice;
        tokenParameters[_id].preSaleIsActive = false;
        tokenParameters[_id].saleIsActive = false;
        tokenParameters[_id].supplyLock = false;
        tokenParameters[_id].totalSupply = 0;
    }

    function mint(
        uint256 _id,
        bytes memory _data,
        uint256 _quantity,
        bytes32[] memory proof
    ) public payable {
        uint _maxSupply = tokenParameters[_id].maxSupply;
        uint _maxPerWallet = tokenParameters[_id].maxPerWallet;
        uint _maxPerTransaction = tokenParameters[_id].maxPerTransaction;
        uint _preSalePrice = tokenParameters[_id].preSalePrice;
        uint _pubSalePrice = tokenParameters[_id].pubSalePrice;
        bool _saleIsActive = tokenParameters[_id].saleIsActive;
        bool _preSaleIsActive = tokenParameters[_id].preSaleIsActive;
        uint _currentSupply = tokenParameters[_id].totalSupply;

        require(_saleIsActive, "Sale is not active.");
        require(_currentSupply <= _maxSupply, "Sold out.");
        require(_currentSupply + _quantity <= _maxSupply, "Requested quantity would exceed total supply.");
        if(_preSaleIsActive) {
            require(_preSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerWallet, "Exceeds wallet presale limit.");
            uint mintedAmount = hasMinted[_id][msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Exceeds per wallet presale limit.");
            hasMinted[_id][msg.sender] = mintedAmount;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(verify(_id, leaf, proof), "You are not whitelisted.");
        } else {
            require(_pubSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        _mint(msg.sender, _id, _quantity, _data);
        tokenParameters[_id].totalSupply = _currentSupply + _quantity;
    }

    function setMultiSig(address payable _address) public onlyMultisig {
        multisigAddress = _address;
    }

    function reserve(uint256 _id, bytes memory _data, address _address, uint256 _quantity) public onlyMultisig {
        _mint(_address, _id, _quantity, _data);
    }

    function withdraw() external nonReentrant onlyMultisig {
        uint balance = address(this).balance;
        uint wenMintAmount = balance * wenmintShare / 100;
        (bool sentWenMint, ) = wentMintAddress.call{ value: wenMintAmount }("");
        require(sentWenMint, "Failed to send ETH to WenMint.");
        uint multiSigAmount = balance - wenMintAmount;
        (bool sentMultiSig, ) = multisigAddress.call{ value: multiSigAmount }("");
        require(sentMultiSig, "Failed to send ETH to Gnosis Safe.");
    }
}