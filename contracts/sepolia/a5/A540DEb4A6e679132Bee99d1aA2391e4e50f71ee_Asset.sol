// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/eip/ERC1155.sol";
import "@thirdweb-dev/contracts/eip/interface/IERC1155Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Asset is ERC1155, Ownable, ReentrancyGuard, IERC1155Enumerable {
    uint256 private _currentTokenId = 0;
    mapping(uint256 => address) public originalOwnerOfAsset;

    mapping(address => bool) private authorizedOwners;
    AggregatorV3Interface internal priceFeedUSD;

    struct AssetData {
        uint256 tokenId;
        string assetType;
        string assetDetails;
        string assetURI;
        uint256 totalShares;
        uint256 remainingShares;
        uint256 pricePerShareUSD;
        bool isDeleted;
    }

    mapping(uint256 => AssetData) public assets;
    mapping(uint256 => mapping(address => uint256))
        public partialOwnershipShares; // mapping of asset ID to mapping of address to partial ownership shares

    mapping(uint256 => address[]) public assetOwners;

    event AssetInstanceCreated(string assetType, uint256 tokenId);
    event TotalPriceCalculated(uint256 totalPrice);

    event AssetPurchased(
        address indexed buyer,
        uint256 assetId,
        uint256 shares,
        uint256 price
    );
    event PartialOwnershipTransferred(
        uint256 assetId,
        address indexed from,
        address indexed to,
        uint256 shares
    );

    constructor(
        address _priceFeedUSD,
        string memory _name,
        string memory _symbol
    ) ERC1155(_name, _symbol) {
        priceFeedUSD = AggregatorV3Interface(_priceFeedUSD);
        addAuthorizedOwner(msg.sender);
    }

    // Other functions and modifiers ...

    modifier onlyAuthorizedOwner() {
        require(
            authorizedOwners[msg.sender],
            "Caller is not an authorized owner"
        );
        _;
    }

    function addAuthorizedOwner(address newOwner) public onlyOwner {
        authorizedOwners[newOwner] = true;
    }

    function removeAuthorizedOwner(address ownerToRemove) public onlyOwner {
        authorizedOwners[ownerToRemove] = false;
    }

    function transferPartialOwnership(
        uint256 assetId,
        address newOwner,
        uint256 shares
    ) internal {
        require(_exists(assetId), "Asset: nonexistent token");
        require(
            partialOwnershipShares[assetId][originalOwnerOfAsset[assetId]] >=
                shares,
            "Asset: insufficient ownership to transfer"
        );
        partialOwnershipShares[assetId][
            originalOwnerOfAsset[assetId]
        ] -= shares;
        partialOwnershipShares[assetId][newOwner] += shares;
        if (!isAssetOwner(assetId, newOwner)) {
            assetOwners[assetId].push(newOwner);
        }
        emit PartialOwnershipTransferred(assetId, msg.sender, newOwner, shares);
    }

    function isAssetOwner(
        uint256 assetId,
        address owner
    ) internal view returns (bool) {
        for (uint i = 0; i < assetOwners[assetId].length; i++) {
            if (assetOwners[assetId][i] == owner) {
                return true;
            }
        }
        return false;
    }

    function createAsset(
        string memory assetType,
        string memory assetDetails,
        string memory assetURI,
        uint256 totalShares,
        uint256 pricePerShareUSD
    ) public onlyAuthorizedOwner returns (uint256) {
        require(
            bytes(assetType).length > 0,
            "Asset: assetType must not be empty"
        );
        require(
            bytes(assetDetails).length > 0,
            "Asset: assetDetails must not be empty"
        );
        require(
            bytes(assetURI).length > 0,
            "Asset: assetURI must not be empty"
        );
        require(totalShares > 0, "Asset: _totalShares must be greater than 0");
        require(
            totalShares * pricePerShareUSD > 0,
            "Asset: total price must be greater than 0"
        );
        uint256 newTokenId = _currentTokenId;

        _mint(address(msg.sender), newTokenId, totalShares, "");

        originalOwnerOfAsset[newTokenId] = msg.sender;

        assets[_currentTokenId] = AssetData(
            _currentTokenId,
            assetType,
            assetDetails,
            assetURI,
            totalShares,
            totalShares, // remainingShares
            pricePerShareUSD,
            false
        );
        partialOwnershipShares[newTokenId][msg.sender] = totalShares;
        assetOwners[_currentTokenId].push(msg.sender);
        _currentTokenId += 1;

        emit AssetInstanceCreated(assetType, newTokenId);

        return newTokenId;
    }

    function buyAssetShares(
        uint256 assetId,
        uint256 shares
    ) public payable nonReentrant {
        require(_exists(assetId), "Asset: nonexistent token");
        require(
            shares <= assets[assetId].remainingShares,
            "Asset: Not enough shares left"
        );

        uint256 pricePerShareWEI = getPricePerShareWEI(assetId);
        uint256 totalPrice = pricePerShareWEI * shares;
        emit TotalPriceCalculated(totalPrice);

        require(msg.value >= totalPrice, "Asset: Insufficient funds sent");
        require(shares > 0, "Asset: Shares must be greater than 0");

        uint256 remainingEther = msg.value - totalPrice;
        if (remainingEther > 0) {
            totalPrice -= remainingEther;
        }

        address assetOwner = originalOwnerOfAsset[assetId];
        (bool sent, ) = payable(assetOwner).call{value: totalPrice}("");

        if (sent) {
            assets[assetId].remainingShares -= shares;
            _safeTransferFrom(assetOwner, msg.sender, assetId, shares, "");
            transferPartialOwnership(assetId, msg.sender, shares);
            emit AssetPurchased(msg.sender, assetId, shares, totalPrice);
        }
    }

    function convertUSDtoWEI(
        uint256 amountUSD
    ) internal view returns (uint256, uint256, uint256) {
        (, int priceInt, , , ) = priceFeedUSD.latestRoundData();
        require(priceInt > 0, "Asset: Failed to get the ETH price");
        uint256 price = uint256(priceInt) / 1e8;
        uint256 amountWEI = (amountUSD * 1e18 * 1e18) / price;
        return (price, amountUSD, amountWEI / 1e18);
    }

    function getOwners(uint256 assetId) public view returns (address[] memory) {
        return assetOwners[assetId];
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Asset: URI query for nonexistent token");
        return
            string(abi.encodePacked(baseTokenURI(), assets[tokenId].assetURI));
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return
            string(abi.encodePacked(baseTokenURI(), assets[_tokenId].assetURI));
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function getPartialOwnerships(
        uint256 assetId
    ) public view returns (address[] memory, uint256[] memory) {
        address[] memory owners = getOwners(assetId); // Assuming there's a function that returns an array of owners
        uint256[] memory shares = new uint256[](owners.length);

        for (uint i = 0; i < owners.length; i++) {
            shares[i] = partialOwnershipShares[assetId][owners[i]];
        }

        return (owners, shares);
    }

    function getPricePerShareWEI(
        uint256 assetId
    ) public view returns (uint256) {
        uint256 pricePerShareUSD = assets[assetId].pricePerShareUSD;
        (, , uint256 pricePerShareWEI) = convertUSDtoWEI(pricePerShareUSD);
        return pricePerShareWEI;
    }

    function getAllAssetsWithDeleted()
        public
        view
        returns (AssetData[] memory)
    {
        AssetData[] memory allAssets = new AssetData[](_currentTokenId);
        for (uint256 i = 0; i < _currentTokenId; i++) {
            allAssets[i] = assets[i];
        }
        return allAssets;
    }

    function getAllAssets()
        public
        view
        returns (AssetData[] memory, uint256[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < _currentTokenId; i++) {
            if (!assets[i].isDeleted) {
                count++;
            }
        }

        AssetData[] memory allAssets = new AssetData[](count);
        uint256[] memory assetIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < _currentTokenId; i++) {
            if (!assets[i].isDeleted) {
                allAssets[index] = assets[i];
                assetIds[index] = i;
                index++;
            }
        }
        return (allAssets, assetIds);
    }

    function deleteAsset(uint256 assetId) public onlyOwner {
        require(_exists(assetId), "Asset: nonexistent token");
        assets[assetId].isDeleted = true;
    }

    function isAuthorizedOwner(address _address) public view returns (bool) {
        return authorizedOwners[_address];
    }

    function isContractOwner(address _address) public view returns (bool) {
        return owner() == _address;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentTokenId;
    }

    function getOriginalOwnerOfAsset(
        uint256 tokendId
    ) public view returns (address) {
        return originalOwnerOfAsset[tokendId];
    }

    function getAssetsByOwner(
        address owner
    ) public view returns (AssetData[] memory, uint256[] memory) {
        uint256 ownedCount = 0;
        for (uint256 i = 0; i < _currentTokenId; i++) {
            if (!assets[i].isDeleted && partialOwnershipShares[i][owner] > 0) {
                ownedCount++;
            }
        }

        AssetData[] memory ownedAssets = new AssetData[](ownedCount);
        uint256[] memory assetIds = new uint256[](ownedCount);

        uint256 counter = 0;
        for (uint256 i = 0; i < _currentTokenId; i++) {
            if (!assets[i].isDeleted && partialOwnershipShares[i][owner] > 0) {
                ownedAssets[counter] = assets[i];
                assetIds[counter] = i;
                counter++;
            }
        }
        return (ownedAssets, assetIds);
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmT6hfRwXFuDcUKWZYBRq9bwi2EqyUf8tGzUhfF3tTChWq?filename=collection.json";
    }

    function nextTokenIdToMint() external view override returns (uint256) {
        return _currentTokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./interface/IERC1155.sol";
import "./interface/IERC1155Metadata.sol";
import "./interface/IERC1155Receiver.sol";

contract ERC1155 is IERC1155, IERC1155Metadata {
    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => string) internal _uri;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _uri[tokenId];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "LENGTH_MISMATCH");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf[accounts[i]][ids[i]];
        }

        return batchBalances;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC1155 logic
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual override {
        address owner = msg.sender;
        require(owner != operator, "APPROVING_SELF");
        isApprovedForAll[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "!OWNER_OR_APPROVED");
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "!OWNER_OR_APPROVED");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /*//////////////////////////////////////////////////////////////
                            Internal logic
    //////////////////////////////////////////////////////////////*/

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "TO_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = balanceOf[from][id];
        require(fromBalance >= amount, "INSUFFICIENT_BAL");
        unchecked {
            balanceOf[from][id] = fromBalance - amount;
        }
        balanceOf[to][id] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");
        require(to != address(0), "TO_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balanceOf[from][id];
            require(fromBalance >= amount, "INSUFFICIENT_BAL");
            unchecked {
                balanceOf[from][id] = fromBalance - amount;
            }
            balanceOf[to][id] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setTokenURI(uint256 tokenId, string memory newuri) internal virtual {
        _uri[tokenId] = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "TO_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        balanceOf[to][id] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "TO_ZERO_ADDR");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            balanceOf[to][ids[i]] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "FROM_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = balanceOf[from][id];
        require(fromBalance >= amount, "INSUFFICIENT_BAL");
        unchecked {
            balanceOf[from][id] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "FROM_ZERO_ADDR");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balanceOf[from][id];
            require(fromBalance >= amount, "INSUFFICIENT_BAL");
            unchecked {
                balanceOf[from][id] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("TOKENS_REJECTED");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("!ERC1155RECEIVER");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("TOKENS_REJECTED");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("!ERC1155RECEIVER");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title ERC1155 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
interface IERC1155Enumerable {
    /// @notice Returns the next token ID available for minting
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function nextTokenIdToMint() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI may point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
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
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}