//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./AssetBaseERC1155.sol";

// solhint-disable-next-line no-empty-blocks
contract AssetERC1155 is AssetBaseERC1155 {
    uint256 private constant CHAIN_INDEX_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32);

    event PredicateSet(address predicate);

    function initialize(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        IAssetERC721 assetERC721,
        uint8 chainIndex
    ) external {
        init(trustedForwarder, admin, bouncerAdmin, assetERC721, chainIndex);
    }

    /// @notice Mint a token type for `creator` on slot `packId`.
    /// @dev Function implementation reserved for future use cases on L1.
    /// @dev For this function it is not required to provide data.
    /// @param creator address of the creator of the token.
    /// @param packId unique packId for that token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the token type in the file 0.json.
    /// @param supply number of tokens minted for that token type.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return id the id of the newly minted token type.
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        address owner,
        bytes calldata data
    ) external returns (uint256 id) {
        require(hash != 0, "HASH==0");
        require(isBouncer(_msgSender()), "!BOUNCER");
        require(owner != address(0), "TO==0");
        id = _generateTokenId(creator, supply, packId, supply == 1 ? 0 : 1, 0);
        uint256 uriId = id & ERC1155ERC721Helper.URI_ID;
        require(uint256(_metadataHash[uriId]) == 0, "ID_TAKEN");
        _metadataHash[uriId] = hash;
        _mint(_msgSender(), owner, id, supply, data);
    }

    /// @notice Creates `amount` tokens of token type `id`, and assigns them to `account`.
    /// @dev Should be callable only by AssetERC1155Tunnel.
    /// @dev Encoded bytes32 metadata hash must be provided as data.
    /// Make sure minting is done only by this function.
    /// @param account user address for whom token is being minted.
    /// @param id token which is being minted.
    /// @param amount amount of token being minted.
    /// @param data token metadata.
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external {
        require(_msgSender() == _predicate, "!PREDICATE");
        require(data.length > 0, "METADATA_MISSING");
        require(account != address(0), "TO==0");
        uint256 uriId = id & ERC1155ERC721Helper.URI_ID;
        require(uint256(_metadataHash[uriId]) == 0, "ID_TAKEN");
        _metadataHash[uriId] = abi.decode(data, (bytes32));
        _mint(_msgSender(), account, id, amount, data);
    }

    /// @notice Creates `amounts` tokens of token types `ids`, and assigns them to `account`.
    /// @dev Should be callable only by AssetERC1155Tunnel.
    /// @dev Encoded bytes32[] metadata hashes must be provided as data.
    /// @param to address to mint to.
    /// @param ids ids to mint.
    /// @param amounts supply for each token type.
    /// @param data token metadata.
    function mintMultiple(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(_msgSender() == _predicate, "!PREDICATE");
        require(data.length > 0, "METADATA_MISSING");
        require(to != address(0), "TO==0");
        bytes32[] memory hashes = abi.decode(data, (bytes32[]));
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 uriId = ids[i] & ERC1155ERC721Helper.URI_ID;
            require(uint256(_metadataHash[uriId]) == 0, "ID_TAKEN");
            _metadataHash[uriId] = hashes[i];
        }
        _mintBatch(to, ids, amounts, data);
    }

    /// @notice Set the address that will be able to mint on L1 (limited to custom predicate).
    /// @param predicate address that will be given minting rights for L1.
    function setPredicate(address predicate) external {
        require(_msgSender() == _admin, "!ADMIN");
        _predicate = predicate;
        emit PredicateSet(predicate);
    }

    /// @notice Burns `amount` tokens of type `id`.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burn(uint256 id, uint256 amount) external {
        _burn(_msgSender(), id, amount);
    }

    /// @notice Burns `amount` tokens of type `id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "!AUTHORIZED");
        _burn(from, id, amount);
    }

    function _generateTokenId(
        address creator,
        uint256 supply,
        uint40 packId,
        uint16 numFTs,
        uint16 packIndex
    ) internal view returns (uint256) {
        require(supply > 0 && supply <= ERC1155ERC721Helper.MAX_SUPPLY, "SUPPLY_OUT_OF_BOUNDS");
        return
            uint256(uint160(creator)) *
            ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER + // CREATOR
            (supply == 1 ? uint256(1) * ERC1155ERC721Helper.IS_NFT_OFFSET_MULTIPLIER : 0) + // minted as NFT(1)|FT(0)
            uint256(_chainIndex) *
            CHAIN_INDEX_OFFSET_MULTIPLIER + // mainnet = 0, polygon = 1
            uint256(packId) *
            ERC1155ERC721Helper.PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack)
            numFTs *
            ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER + // number of fungible token in the pack
            packIndex; // packIndex (position in the pack)
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155Receiver.sol";
import "../common/interfaces/IAssetERC721.sol";
import "../common/Libraries/ObjectLib32.sol";
import "../common/BaseWithStorage/WithSuperOperators.sol";
import "../asset/libraries/ERC1155ERC721Helper.sol";

// solhint-disable max-states-count
abstract contract AssetBaseERC1155 is WithSuperOperators, IERC1155 {
    using Address for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;

    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    mapping(address => uint256) private _numNFTPerAddress; // erc721
    mapping(uint256 => uint256) private _owners; // erc721
    mapping(address => mapping(uint256 => uint256)) private _packedTokenBalance; // erc1155
    mapping(address => mapping(address => bool)) private _operatorsForAll; // erc721 and erc1155
    mapping(uint256 => address) private _erc721operators; // erc721
    mapping(uint256 => bytes32) internal _metadataHash; // erc721 and erc1155
    mapping(uint256 => bytes) internal _rarityPacks; // rarity configuration per packs (2 bits per Asset) *DEPRECATED*
    mapping(uint256 => uint32) private _nextCollectionIndex; // extraction

    // @note : Deprecated.
    mapping(address => address) private _creatorship; // creatorship transfer // deprecated

    mapping(address => bool) private _bouncers; // the contracts allowed to mint

    // @note : Deprecated.
    mapping(address => bool) private _metaTransactionContracts;

    address private _bouncerAdmin;

    bool internal _init;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    uint256 internal _initBits;
    address internal _predicate; // used in place of polygon's `PREDICATE_ROLE`

    uint8 internal _chainIndex; // modify this for l2

    address internal _trustedForwarder;

    IAssetERC721 public _assetERC721;

    uint256[20] private __gap;
    // solhint-enable max-states-count

    event BouncerAdminChanged(address oldBouncerAdmin, address newBouncerAdmin);
    event Bouncer(address bouncer, bool enabled);
    event Extraction(uint256 indexed id, uint256 indexed newId);
    event AssetERC721Set(IAssetERC721 assetERC721);

    function init(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        IAssetERC721 assetERC721,
        uint8 chainIndex
    ) public {
        // one-time init of bitfield's previous versions
        _checkInit(1);
        _admin = admin;
        _bouncerAdmin = bouncerAdmin;
        _assetERC721 = assetERC721;
        __ERC2771Handler_initialize(trustedForwarder);
        _chainIndex = chainIndex;
    }

    /// @notice Change the minting administrator to be `newBouncerAdmin`.
    /// @param newBouncerAdmin address of the new minting administrator.
    function changeBouncerAdmin(address newBouncerAdmin) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        require(newBouncerAdmin != address(0), "AssetBaseERC1155: new bouncer admin can't be zero address");
        emit BouncerAdminChanged(_bouncerAdmin, newBouncerAdmin);
        _bouncerAdmin = newBouncerAdmin;
    }

    /// @notice Enable or disable the ability of `bouncer` to mint tokens (minting bouncer rights).
    /// @param bouncer address that will be given/removed minting bouncer rights.
    /// @param enabled set whether the address is enabled or disabled as a minting bouncer.
    function setBouncer(address bouncer, bool enabled) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        _bouncers[bouncer] = enabled;
        emit Bouncer(bouncer, enabled);
    }

    /// @notice Transfers `value` tokens of type `id` from  `from` to `to`  (with safety call).
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param id the token type transfered.
    /// @param value amount of token transfered.
    /// @param data aditional data accompanying the transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        bool success = _transferFrom(from, to, id, value);
        if (success) {
            require(
                _checkOnERC1155Received(isTrustedForwarder(msg.sender) ? from : msg.sender, from, to, id, value, data),
                "1155_TRANSFER_REJECTED"
            );
        }
    }

    /// @notice Transfers `values` tokens of type `ids` from  `from` to `to` (with safety call).
    /// @dev call data should be optimized to order ids so packedBalance can be used efficiently.
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param ids ids of each token type transfered.
    /// @param values amount of each token type transfered.
    /// @param data aditional data accompanying the transfer.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "MISMATCHED_ARR_LEN");
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        bool metaTx = isTrustedForwarder(msg.sender);
        bool authorized = from == _msgSender() || isApprovedForAll(from, _msgSender());

        _batchTransferFrom(from, to, ids, values, authorized);
        emit TransferBatch(metaTx ? from : _msgSender(), from, to, ids, values);
        require(
            _checkOnERC1155BatchReceived(metaTx ? from : _msgSender(), from, to, ids, values, data),
            "1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Enable or disable approval for `operator` to manage all `sender`'s tokens.
    /// @dev used for Meta Transaction (from metaTransactionContract).
    /// @param sender address which grant approval.
    /// @param operator address which will be granted rights to transfer all token owned by `sender`.
    /// @param approved whether to approve or revoke.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender == _msgSender() || _superOperators[_msgSender()], "!AUTHORIZED");
        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Enable or disable approval for `operator` to manage all of the caller's tokens.
    /// @param operator address which will be granted rights to transfer all tokens of the caller.
    /// @param approved whether to approve or revoke
    function setApprovalForAll(address operator, bool approved) external override(IERC1155) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Returns the current administrator in charge of minting rights.
    /// @return the current minting administrator in charge of minting rights.
    function getBouncerAdmin() external view returns (address) {
        return _bouncerAdmin;
    }

    /// @notice check whether address `who` is given minting bouncer rights.
    /// @param who The address to query.
    /// @return whether the address has minting rights.
    function isBouncer(address who) public view returns (bool) {
        return _bouncers[who];
    }

    /// @notice Get the balance of `owners` for each token type `ids`.
    /// @param owners the addresses of the token holders queried.
    /// @param ids ids of each token type to query.
    /// @return the balance of each `owners` for each token type `ids`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(owners.length == ids.length, "ARG_LENGTH_MISMATCH");
        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }
        return balances;
    }

    /// @notice A descriptive name for the collection of tokens in this contract.
    /// @return _name the name of the tokens.
    function name() external pure returns (string memory _name) {
        return "Sandbox's ASSETs";
    }

    /// @notice An abbreviated name for the collection of tokens in this contract.
    /// @return _symbol the symbol of the tokens.
    function symbol() external pure returns (string memory _symbol) {
        return "ASSET";
    }

    /// @notice Query if a contract implements interface `id`.
    /// @param id the interface identifier, as specified in ERC-165.
    /// @return `true` if the contract implements `id`.
    function supportsInterface(bytes4 id) external pure override returns (bool) {
        return
            id == 0x01ffc9a7 || //ERC165
            id == 0xd9b67a26 || // ERC1155
            id == 0x0e89341c || // ERC1155 metadata
            id == 0x9930ed5a; // ERC2771
    }

    /// @notice Gives the collection a specific token belongs to.
    /// @param id the token to get the collection of.
    /// @return the collection the NFT is part of.
    function collectionOf(uint256 id) public view returns (uint256) {
        require(wasEverMinted(id), "FT_!MINTED"); // TODO: review
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        require(wasEverMinted(collectionId), "UNMINTED_COLLECTION");
        return collectionId;
    }

    /// @notice Return wether the id is a collection
    /// @param id collectionId to check.
    /// @return whether the id is a collection.
    function isCollection(uint256 id) public view returns (bool) {
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        return wasEverMinted(collectionId);
    }

    /// @notice Gives the index at which an NFT was minted in a collection : first of a collection get the zero index.
    /// @param id the token to get the index of.
    /// @return the index/order at which the token `id` was minted in a collection.
    function collectionIndexOf(uint256 id) public view returns (uint256) {
        collectionOf(id); // this check if id and collection indeed was ever minted
        return uint32((id & ERC1155ERC721Helper.NFT_INDEX) >> ERC1155ERC721Helper.NFT_INDEX_OFFSET);
    }

    function wasEverMinted(uint256 id) public view returns (bool) {
        // TODO: discuss
        // ((id & ERC1155ERC721Helper.PACK_INDEX) <
        //     ((id & ERC1155ERC721Helper.PACK_NUM_FT_TYPES) /
        //         ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER)) &&
        return _metadataHash[id & ERC1155ERC721Helper.URI_ID] != 0;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param id token to get the uri of.
    /// @return URI string
    function tokenURI(uint256 id) public view returns (string memory) {
        require(wasEverMinted(id), "FT_!MINTED");
        return ERC1155ERC721Helper.toFullURI(_metadataHash[id & ERC1155ERC721Helper.URI_ID], id);
    }

    /// @notice Get the balance of `owner` for the token type `id`.
    /// @param owner The address of the token holder.
    /// @param id the token type of which to get the balance of.
    /// @return the balance of `owner` for the token type `id`.
    function balanceOf(address owner, uint256 id) public view override returns (uint256) {
        require(wasEverMinted(id), "token was never minted");
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedTokenBalance[owner][bin].getValueInBin(index);
    }

    /// @notice Extracts an EIP-721 Asset from an EIP-1155 Asset.
    /// @param sender address which own the token to be extracted.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return newId the id of the newly minted NFT.
    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256) {
        require(sender == _msgSender() || isApprovedForAll(sender, _msgSender()), "!AUTHORIZED");
        require(to != address(0), "TO==0");
        require(id & ERC1155ERC721Helper.IS_NFT == 0, "NOT_ERC1155_TOKEN");
        uint32 tokenCollectionIndex = _nextCollectionIndex[id];
        string memory metaData = tokenURI(id);
        uint256 newId =
            id + ERC1155ERC721Helper.IS_NFT + (tokenCollectionIndex) * 2**ERC1155ERC721Helper.NFT_INDEX_OFFSET;
        _nextCollectionIndex[id] = tokenCollectionIndex + 1;
        _burnFT(sender, id, 1);
        _assetERC721.mint(to, newId, bytes(abi.encode(metaData)));
        emit Extraction(id, newId);
        return newId;
    }

    function setAssetERC721(IAssetERC721 assetERC721) external returns (bool) {
        require(_admin == _msgSender(), "AUTHORIZED");
        _assetERC721 = assetERC721;
        emit AssetERC721Set(assetERC721);
        return true;
    }

    /// @notice Queries the approval status of `operator` for owner `owner`.
    /// @param owner the owner of the tokens.
    /// @param operator address of authorized operator.
    /// @return isOperator true if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC1155)
        returns (bool isOperator)
    {
        require(owner != address(0), "OWNER==0");
        require(operator != address(0), "OPERATOR==0");
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(sender != address(0), "SENDER==0");
        require(sender != operator, "SENDER==OPERATOR");
        require(operator != address(0), "OPERATOR==0");
        require(!_superOperators[operator], "APPR_EXISTING_SUPEROPERATOR");
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /* solhint-disable code-complexity */
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bool authorized
    ) internal {
        uint256 numItems = ids.length;
        uint256 bin;
        uint256 index;
        uint256 balFrom;
        uint256 balTo;

        uint256 lastBin;
        require(authorized, "OPERATOR_!AUTH");

        for (uint256 i = 0; i < numItems; i++) {
            if (from == to) {
                _checkEnoughBalance(from, ids[i], values[i]);
            } else if (values[i] > 0) {
                (bin, index) = ids[i].getTokenBinIndex();
                if (lastBin == 0) {
                    lastBin = bin;
                    balFrom = ObjectLib32.updateTokenBalance(
                        _packedTokenBalance[from][bin],
                        index,
                        values[i],
                        ObjectLib32.Operations.SUB
                    );
                    balTo = ObjectLib32.updateTokenBalance(
                        _packedTokenBalance[to][bin],
                        index,
                        values[i],
                        ObjectLib32.Operations.ADD
                    );
                } else {
                    if (bin != lastBin) {
                        _packedTokenBalance[from][lastBin] = balFrom;
                        _packedTokenBalance[to][lastBin] = balTo;
                        balFrom = _packedTokenBalance[from][bin];
                        balTo = _packedTokenBalance[to][bin];
                        lastBin = bin;
                    }

                    balFrom = balFrom.updateTokenBalance(index, values[i], ObjectLib32.Operations.SUB);
                    balTo = balTo.updateTokenBalance(index, values[i], ObjectLib32.Operations.ADD);
                }
            }
        }

        if (bin != 0 && from != to) {
            _packedTokenBalance[from][bin] = balFrom;
            _packedTokenBalance[to][bin] = balTo;
        }
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        require(amount > 0 && amount <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
        _burnFT(from, id, uint32(amount));
        emit TransferSingle(_msgSender(), from, address(0), id, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        address operator = isTrustedForwarder(msg.sender) ? from : _msgSender();
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i] > 0 && amounts[i] <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
            _burnFT(from, ids[i], uint32(amounts[i]));
        }
        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _burnFT(
        address from,
        uint256 id,
        uint32 amount
    ) internal {
        (uint256 bin, uint256 index) = (id).getTokenBinIndex();
        _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
            index,
            amount,
            ObjectLib32.Operations.SUB
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint16 offset = 0;
        while (offset < amounts.length) {
            _mintPack(offset, amounts, to, ids);
            offset += 8;
        }
        _completeBatchMint(_msgSender(), to, ids, amounts, data);
    }

    function _mintPack(
        uint16 offset,
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids
    ) internal {
        (uint256 bin, uint256 index) = ids[offset].getTokenBinIndex();
        for (uint256 i = 0; i < 8 && offset + i < supplies.length; i++) {
            uint256 j = offset + i;
            if (supplies[j] > 0) {
                _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin].updateTokenBalance(
                    index + i,
                    supplies[j],
                    ObjectLib32.Operations.ADD
                );
            }
        }
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal returns (bool) {
        address sender = _msgSender();
        bool authorized = from == sender || isApprovedForAll(from, sender);

        require(authorized, "OPERATOR_!AUTH");
        if (value > 0) {
            (uint256 bin, uint256 index) = id.getTokenBinIndex();
            _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
                index,
                value,
                ObjectLib32.Operations.SUB
            );
            _packedTokenBalance[to][bin] = _packedTokenBalance[to][bin].updateTokenBalance(
                index,
                value,
                ObjectLib32.Operations.ADD
            );
        }

        emit TransferSingle(isTrustedForwarder(msg.sender) ? from : sender, from, to, id, value);
        return true;
    }

    function _mint(
        address operator,
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        _packedTokenBalance[account][bin] = _packedTokenBalance[account][bin].updateTokenBalance(
            index,
            amount,
            ObjectLib32.Operations.REPLACE
        );

        emit TransferSingle(operator, address(0), account, id, amount);
        require(_checkOnERC1155Received(operator, address(0), account, id, amount, data), "TRANSFER_REJECTED");
    }

    /// @dev Allows the use of a bitfield to track the initialized status of the version `v` passed in as an arg.
    /// If the bit at the index corresponding to the given version is already set, revert.
    /// Otherwise, set the bit and return.
    /// @param v The version of this contract.
    function _checkInit(uint256 v) internal {
        require((_initBits >> v) & uint256(1) != 1, "ALREADY_INITIALISED");
        _initBits = _initBits | (uint256(1) << v);
    }

    function _completeBatchMint(
        address operator,
        address owner,
        uint256[] memory ids,
        uint256[] memory supplies,
        bytes memory data
    ) internal {
        emit TransferBatch(operator, address(0), owner, ids, supplies);
        require(_checkOnERC1155BatchReceived(operator, address(0), owner, ids, supplies, data), "TRANSFER_REJECTED");
    }

    function _checkEnoughBalance(
        address from,
        uint256 id,
        uint256 value
    ) internal view {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        require(_packedTokenBalance[from][bin].getValueInBin(index) >= value, "BALANCE_TOO_LOW");
    }

    function _checkOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        return IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) == ERC1155_RECEIVED;
    }

    function _checkOnERC1155BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data);
        return (retval == ERC1155_BATCH_RECEIVED);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Base} from "./IERC721Base.sol";

interface IAssetERC721 is IERC721Base {
    function mint(address to, uint256 id) external override;

    function mint(
        address to,
        uint256 id,
        bytes calldata data
    ) external override;

    function setTokenURI(uint256 id, string memory uri) external;

    function tokenURI(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

library ObjectLib32 {
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 internal constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 internal constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /// @dev Return the bin number and index within that bin where ID is
    /// @param tokenId Object type
    /// @return bin Bin number.
    /// @return index ID's index within that bin.
    function getTokenBinIndex(uint256 tokenId) internal pure returns (uint256 bin, uint256 index) {
        unchecked {bin = (tokenId * TYPES_BITS_SIZE) / 256;}
        index = tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in binBalances
     * @param binBalances Uint256 containing the balances of objects
     * @param index Index of the object in the provided bin
     * @param amount Value to update the type balance
     * @param operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with amount
     *     Operations.ADD     : ADD amount to type balance
     *     Operations.SUB     : Substract amount from type balance
     */
    function updateTokenBalance(
        uint256 binBalances,
        uint256 index,
        uint256 amount,
        Operations operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (operation == Operations.ADD) {
            objectBalance = getValueInBin(binBalances, index);
            newBinBalance = writeValueInBin(binBalances, index, objectBalance + amount);
        } else if (operation == Operations.SUB) {
            objectBalance = getValueInBin(binBalances, index);
            require(objectBalance >= amount, "can't substract more than there is");
            newBinBalance = writeValueInBin(binBalances, index, objectBalance - amount);
        } else if (operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(binBalances, index, amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in binValue at position index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index index at which to retrieve value
     * @return Value at given index in bin
     */
    function getValueInBin(uint256 binValue, uint256 index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated binValue after writing amount at index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index Index at which to retrieve value
     * @param amount Value to store at index in bin
     * @return Value at given index in bin
     */
    function writeValueInBin(
        uint256 binValue,
        uint256 index,
        uint256 amount
    ) internal pure returns (uint256) {
        require(amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithSuperOperators is WithAdmin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library ERC1155ERC721Helper {
    bytes32 private constant base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;

    uint256 public constant CREATOR_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 public constant IS_NFT_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1);
    uint256 public constant PACK_ID_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40);
    uint256 public constant PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40 - 12);
    uint256 public constant NFT_INDEX_OFFSET = 63;

    uint256 public constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 public constant NOT_IS_NFT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant NFT_INDEX = 0x00000000000000000000000000000000000000007FFFFFFF8000000000000000;
    uint256 public constant NOT_NFT_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000007FFFFFFFFFFFFFFF;
    uint256 public constant URI_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFFFFF800;
    uint256 public constant PACK_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFF800000;
    uint256 public constant PACK_INDEX = 0x00000000000000000000000000000000000000000000000000000000000007FF;
    uint256 public constant PACK_NUM_FT_TYPES = 0x00000000000000000000000000000000000000000000000000000000007FF800;

    uint256 public constant MAX_SUPPLY = uint256(2)**32 - 1;
    uint256 public constant MAX_PACK_SIZE = uint256(2)**11;

    function toFullURI(bytes32 hash, uint256 id) public pure returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", uint2str(id & PACK_INDEX), ".json"));
    }

    // solium-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash) public pure returns (string memory _uintAsString) {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }

    // solium-disable-next-line security/no-assign-params
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + uint8(_i % 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ExtendedToken} from "./IERC721ExtendedToken.sol";

interface IERC721Base is IERC721Upgradeable {
    function mint(address to, uint256 id) external;

    function mint(
        address to,
        uint256 id,
        bytes calldata metaData
    ) external;

    function approveFor(
        address from,
        address operator,
        uint256 id
    ) external;

    function setApprovalForAllFor(
        address from,
        address operator,
        bool approved
    ) external;

    function burnFrom(address from, uint256 id) external;

    function burn(uint256 id) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function exists(uint256 tokenId) external view returns (bool);

    function supportsInterface(bytes4 id) external view override returns (bool);

    function setTrustedForwarder(address trustedForwarder) external;

    function isTrustedForwarder(address forwarder) external returns (bool);

    function getTrustedForwarder() external returns (address trustedForwarder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC721ExtendedToken {
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function burn(uint256 id) external;

    function burnFrom(address from, uint256 id) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}