// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "./pixel_prismatica_data.sol";
import "./standard_contract.sol";

// import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

// import "@openzeppelin/contracts/interfaces/IERC2981.sol";
interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

contract PixelPrismatica is StandardContract, IERC1155MetadataURI, IERC2981 {
    /*
    *
    *
        Errors
    *
    *
    */

    /// @notice The required minting fee has not been paid.
    error MintFeeError(uint256 value, uint256 mintFee);

    /// @notice There are no remaining NFT mints available.
    error NoRemainingMintsError();

    /*
    *
    *
        Events
    *
    *
    */

    /// @notice A record of an NFT being minted.
    event Mint(uint256 indexed id, address indexed mintAddress);

    /*
    *
    *
        Constants
    *
    *
    */

    // The identifier of the chain that this contract is meant to be deployed on.
    uint256 private constant CHAIN_ID = 97; 

    // The max number of NFT mints available.
    uint256 private constant MAX_MINTS = 100;

    /*
    *
    *
        Private Variables
    *
    *
    */

    /*
        NFT Variables
    */
    PixelPrismaticaData private constant DATA = PixelPrismaticaData(0x2E6b5dFa714cC9Ab06B4D41e5012b57D00F9F6B7);

    uint256 private currentID;

    uint256 private mintFee;
    address private royaltyAddress;
    uint256 private royaltyBasisPoints;
    
    string private storeDescription;
    string private storeExternalLinkURI;
    string private storeImageURI;
    string private storeName;

    mapping(uint256 => uint256) private map_id2Config;

    mapping(address => mapping(address => bool)) private map_address2OperatorAddress2IsApproved;
    mapping(uint256 => mapping(address => uint256)) private map_id2Address2Balance;

    /*
    *
    *
        Contract Functions
    *
    *
    */

    /*
        Built-In Functions
    */

    constructor() StandardContract() payable {
        //assert(block.chainid == CHAIN_ID);

        // The contract starts paused to allow NFT information to be set.
        //setPause(true);

        // Set the initial mint fee. This will increase automatically as more NFTs are minted.
        setMintFee(0 ether);

        // The royalty is fixed at 3%
        setRoyaltyBasisPoints(300);

        // Defaults are set here, but these can be changed manually after the contract is deployed.
        setRoyaltyAddress(address(this));
        setStoreName("X Prismatica NFT Collection");
        setStoreDescription("A collection of configurable NFT tokens featuring colorful pixel art.");
        setStoreImageURI("I");
        setStoreExternalLinkURI("Z");
    }

    fallback() external payable {
        // There is no legitimate reason for this fallback function to be called.
        punish();
    }

    receive() external payable {}

    /*
        Implementation Functions
    */

    // IERC165 Implementation
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, StandardContract) returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId 
            || interfaceId == type(IERC2981).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // IERC1155 Implementation
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return map_id2Address2Balance[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for(uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");

        map_address2OperatorAddress2IsApproved[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return map_address2OperatorAddress2IsApproved[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        requireNotPaused();
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved");

        uint256 fromBalance = map_id2Address2Balance[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");

        map_id2Address2Balance[id][from] = fromBalance - amount;
        map_id2Address2Balance[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        requireNotPaused();
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not token owner or approved");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        for(uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = map_id2Address2Balance[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");

            map_id2Address2Balance[id][from] = fromBalance - amount;
            map_id2Address2Balance[id][to] += amount;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        if(to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if(response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            }
            catch Error(string memory reason) {
                revert(reason);
            }
            catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
        if(to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if(response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            }
            catch Error(string memory reason) {
                revert(reason);
            }
            catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    // IERC1155MetadataURI Implementation
    function uri(uint256 id) external view returns (string memory) {
        // The JSON data is directly encoded here.
        string memory name = string.concat("Pixel Prismatica NFT #", uint256ToString(id));
        string memory description = createDescription(id);
        string memory imageURI = createImageURI(id);

        string memory uriString = string.concat('{"name":"', name, '", "description":"', description, '", "image":"', imageURI, '"}');
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(uriString))));
    }

    // IERC2981 Implementation
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyAddress;
        royaltyAmount = (salePrice * royaltyBasisPoints) / 10000;
    }

    // OpenSea Standard
    function contractURI() public view returns (string memory) {
        // The JSON data is directly encoded here.
        string memory uriString = string.concat('{"name":"', storeName, '", "description":"', storeDescription, '", "image":"', storeImageURI, '", "external_link":"', storeExternalLinkURI, '", "seller_fee_basis_points":', uint256ToString(royaltyBasisPoints), ', "fee_recipient":"', addressToString(royaltyAddress), '"}');
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(abi.encodePacked(uriString))));
    }

    /*
        Action Functions
    */

    function mint(address _address, uint256 _config, bytes memory _data) private {
        // This NFT is always minted one at a time.
        requireNotPaused();
        require(_address != address(0), "ERC1155: mint to the zero address");

        currentID++;

        map_id2Address2Balance[currentID][_address] = 1;
        map_id2Config[currentID] = _config;

        // Every time an NFT is minted, increase the minting cost for the next one.
        setMintFee((getMintFee() * 105) / 100);
        
        emit Mint(currentID, _address);
        emit TransferSingle(msg.sender, address(0), _address, currentID, 1);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), _address, currentID, 1, _data);
    }

    /*
        Helper Functions
    */

    function createDescription(uint256 _id) private view returns (string memory) {
        return string.concat("Configuration: ", DATA.getConfigName(map_id2Config[_id]));
    }

    function createImageURI(uint256 _id) private view returns (string memory) {
        return DATA.getConfigURI(map_id2Config[_id]);
    }

    /*
        Query Functions
    */

    function isMintFee(uint256 _value) private view returns (bool) {
        return _value == getMintFee();
    }

    function isRemainingMints() private view returns (bool) {
        return getRemainingMints() != 0;
    }

    /*
        Require Functions
    */

    function requireMintFee(uint256 _value) private view {
        if(!isMintFee(_value)) {
            revert MintFeeError(_value, getMintFee());
        }
    }

    function requireRemainingMints() private view {
        if(!isRemainingMints()) {
            revert NoRemainingMintsError();
        }
    }

    /*
        Get Functions
    */

    function getMintFee() private view returns (uint256) {
        return mintFee;
    }

    function getRemainingMints() private view returns (uint256) {
        return MAX_MINTS - currentID;
    }

    function getRoyaltyAddress() private view returns (address) {
        return royaltyAddress;
    }

    function getRoyaltyBasisPoints() private view returns (uint256) {
        return royaltyBasisPoints;
    }

    function getStoreDescription() private view returns (string memory) {
        return storeDescription;
    }

    function getStoreExternalLinkURI() private view returns (string memory) {
        return storeExternalLinkURI;
    }

    function getStoreImageURI() private view returns (string memory) {
        return storeImageURI;
    }

    function getStoreName() private view returns (string memory) {
        return storeName;
    }

    function getTotalMints() private view returns (uint256) {
        return currentID;
    }

    /*
        Set Functions
    */

    function setMintFee(uint256 _mintFee) private {
        mintFee = _mintFee;
    }

    function setRoyaltyAddress(address _royaltyAddress) private {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) private {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setStoreDescription(string memory _storeDescription) private {
        storeDescription = _storeDescription;
    }

    function setStoreExternalLinkURI(string memory _storeExternalLinkURI) private {
        storeExternalLinkURI = _storeExternalLinkURI;
    }

    function setStoreImageURI(string memory _storeImageURI) private {
        storeImageURI = _storeImageURI;
    }

    function setStoreName(string memory _storeName) private {
        storeName = _storeName;
    }

    /*
    *
    *
        External Functions
    *
    *
    */

    /*
        Action Functions
    */

    /// @notice A user can mint an NFT for a token address.
    /// @param _config Desired configuration for the NFT.
    /// @param _data Additional data with no specified format.
    function action_mint(uint256 _config, bytes memory _data) external payable {
        lock();

        requireRemainingMints();
        requireMintFee(msg.value);

        mint(msg.sender, _config, _data);

        unlock();
    }

    /// @notice The operator can trigger a mint for someone else.
    /// @param _address The address that the operator is triggering the mint for.
    /// @param _config Desired configuration for the NFT.
    /// @param _data Additional data with no specified format.
    function action_mintOther(address _address, uint256 _config, bytes memory _data) external payable {
        lock();

        requireOperatorAddress(msg.sender);
        requireRemainingMints();
        requireMintFee(msg.value);
        
        mint(_address, _config, _data);

        unlock();
    }

    /*
        Query Functions
    */

    /// @notice Returns whether there are any remaining NFT mints available.
    /// @return Whether there are any remaining NFT mints available.
    function query_isRemainingMints() external view returns (bool) {
        return isRemainingMints();
    }

    /*
        Get Functions
    */

    /// @notice Returns the mint fee.
    /// @return The mint fee.
    function get_mintFee() external view returns (uint256) {
        return getMintFee();
    }

    /// @notice Returns the number of remaining NFT mints available.
    /// @return The number of remaining NFT mints available.
    function get_remainingMints() external view returns (uint256) {
        return getRemainingMints();
    }

    /// @notice Returns the address that royalties will be paid to.
    /// @return The address that royalties will be paid to.
    function get_royaltyAddress() external view returns (address) {
        return getRoyaltyAddress();
    }

    /// @notice Returns the royalty basis points.
    /// @return The royalty basis points.
    function get_royaltyBasisPoints() external view returns (uint256) {
        return getRoyaltyBasisPoints();
    }

    /// @notice Returns the store description.
    /// @return The store description.
    function get_storeDescription() external view returns (string memory) {
        return getStoreDescription();
    }

    /// @notice Returns the store external link URI.
    /// @return The store external link URI.
    function get_storeExternalLinkURI() external view returns (string memory) {
        return getStoreExternalLinkURI();
    }

    /// @notice Returns the store image URI.
    /// @return The store image URI.
    function get_storeImageURI() external view returns (string memory) {
        return getStoreImageURI();
    }

    /// @notice Returns the store name.
    /// @return The store name.
    function get_storeName() external view returns (string memory) {
        return getStoreName();
    }

    /// @notice Returns the total number of NFTs that have been minted.
    /// @return The total number of NFTs that have been minted.
    function get_totalMints() external view returns (uint256) {
        return getTotalMints();
    }

    /*
        Set Functions
    */

    /// @notice The operator can set the address that royalties will be paid to.
    /// @param _royaltyAddress The new first address that royalties will be paid to.
    function set_royaltyAddress(address _royaltyAddress) external {
        lock();

        requireOperatorAddress(msg.sender);

        setRoyaltyAddress(_royaltyAddress);

        unlock();
    }

    /// @notice The operator can set the store description.
    /// @param _storeDescription The new store description.
    function set_storeDescription(string memory _storeDescription) external {
        lock();

        requireOperatorAddress(msg.sender);

        setStoreDescription(_storeDescription);

        unlock();
    }

    /// @notice The operator can set the store external link URI.
    /// @param _storeExternalLinkURI The new store external link URI.
    function set_storeExternalLinkURI(string memory _storeExternalLinkURI) external {
        lock();

        requireOperatorAddress(msg.sender);

        setStoreExternalLinkURI(_storeExternalLinkURI);

        unlock();
    }

    /// @notice The operator can set the store image URI.
    /// @param _storeImageURI The new store image URI.
    function set_storeImageURI(string memory _storeImageURI) external {
        lock();

        requireOperatorAddress(msg.sender);

        setStoreImageURI(_storeImageURI);

        unlock();
    }

    /// @notice The operator can set the store name.
    /// @param _storeName The new store name.
    function set_storeName(string memory _storeName) external {
        lock();

        requireOperatorAddress(msg.sender);

        setStoreName(_storeName);

        unlock();
    }
}