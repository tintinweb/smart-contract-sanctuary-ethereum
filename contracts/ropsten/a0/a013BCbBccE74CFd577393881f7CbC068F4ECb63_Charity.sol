// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Receiver.sol";
import "./IERC20.sol";
import "./ICharity.sol";
import "./IERC20Upgradeable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ISplitter.sol";
import "./SafeERC20Upgradeable.sol";
import "./SplitterUpgradeable.sol";
import "./IERC2981.sol";
import "./LibPart.sol";
import "./RoyaltiesV2.sol";
import "./RoyaltiesV1.sol";



contract Charity is ERC1155, Ownable, ERC1155Receiver, ICharity,
                    IERC2981, RoyaltiesV2, RoyaltiesV1 {

    using Address for address;

    uint256 private _currentTokenID = 0;
    mapping (uint256 => address) public creators;
    mapping (address => address) public splitters;
    mapping (uint256 => uint256) public prices;
    mapping (uint256 => string) public uris;
    mapping (uint256 => uint256) public tokenSupply;
    string public name;
    string public symbol;

    address private management = 0x8c0A12ab2cc16008EF4eda9b25Da67603fc6a333;
    address private charity = 0x02E056FC9aE03d3eaeFEe84C301418F9F522e317;
    uint256 private managementShare = 20;
    uint256 private charityShare = 10;
    uint256 private royalty = 10;

    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
    bytes4 constant _INTERFACE_ID_FEES = 0xb7799584;

    event SplitterCreated(address indexed _creator, address indexed _splitter);
    /**
    * @dev Require msg.sender to be the creator of the token id
    */
    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender, "Charity#creatorOnly: ONLY_CREATOR_ALLOWED");
        _;
    }

    /**
    * @dev Require msg.sender to own more than 0 of the token id
    */
    modifier ownersOnly(uint256 _id) {
        require(balanceOf(_msgSender(), _id) > 0, "Charity: ONLY_OWNERS_ALLOWED");
        _;
    }

    /**
    * @dev Require msg.sender to own more than 0 of the token id
    */
    modifier authorizedOnly(uint256 _id) {
        require((_msgSender() == management ||
                _msgSender() == charity ||
                _msgSender() == creators[_id]), "You don't have permition for this action");
        _;
    }


    constructor() ERC1155 ("") {
        name = "Charity";
        symbol = "Charity";
    }

    function getManagementWallet() public view returns (address) {
        return management;
    }

    function getCharityWallet() public view returns (address) {
        return charity;
    }

    function getCharityShare() public view returns (uint256) {
        return charityShare;
    }

    function getManagementShare() public view returns (uint256) {
        return managementShare;
    }

    function setManagementWallet(address _account) public onlyOwner {
        require(_account != address(0), "Invalid wallet address");
        management = _account;
    }

    function setCharityWallet(address _account) public onlyOwner {
        require(_account != address(0), "Invalid wallet address");
        charity = _account;
    }

    function setManagementShare(uint256 _share) public onlyOwner {
        require(_share <= 100, "Share cannot exceed 100%");
        if (_share + charityShare > 100) {
            charityShare = 100 - _share;
        }
        managementShare = _share;

    }

    function setCharityShare(uint256 _share) public onlyOwner {
        require(_share <= 100, "Share cannot exceed 100%");
        if (_share + managementShare > 100) {
            managementShare = 100 - _share;
        }
        charityShare = _share;
    }

    function setRoyalty(uint256 _share) public onlyOwner {
        require(_share <= 100, "Royalty cannot exceed 100%");
        royalty = _share;
    }


    function getSplitters(uint256[] memory ids)
        public
        view
        returns (address[] memory)
    {
        address[] memory batchSplitters = new address[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            batchSplitters[i] = splitters[creators[ids[i]]];
        }
        return batchSplitters;
    }


    function getCreators(uint256[] memory ids)
        public
        view
        returns (address[] memory)
    {
        address[] memory batchCreators = new address[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            batchCreators[i] = creators[ids[i]];
        }
        return batchCreators;
    }


    function getPrices(uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory batchPrices = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            batchPrices[i] = prices[ids[i]];
        }
        return batchPrices;
    }


    function getSplitterBalances(uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            batchBalances[i] = splitters[creators[ids[i]]].balance;
        }
        return batchBalances;
    }

    function getAvailableTokens(uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            batchBalances[i] = balanceOf(address(this), ids[i]);
        }

        return batchBalances;
    }


    function withdrawETHRoyalty(uint256 _id) external authorizedOnly(_id) {
        require(_exists(_id), "Token doesn't exist");
        address splitter = splitters[creators[_id]];
        uint256 balance = splitter.balance;
        require(balance > 0, "Nothing to withdraw");
        ISplitter(splitter).withdrawETH();
    }

    function withdrawTokenRoyalty(uint256 _id, address _token) external authorizedOnly(_id) {
        require(_exists(_id), "Token doesn't exist");
        require((_token != address(0) && _token.isContract()), "Invalid token address");
        address splitter = splitters[creators[_id]];
        uint256 balance = IERC20(_token).balanceOf(splitter);
        require(balance > 0, "Nothing to withdraw");
        ISplitter(splitter).withdrawToken(_token);
    }



    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155, ERC1155Receiver)
        returns (bool)
    {
        return interfaceId == _INTERFACE_ID_ROYALTIES || interfaceId == _INTERFACE_ID_FEES ||
        interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }


    /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function getBatchSupplies(uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory batchSupplies = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            batchSupplies[i] = totalSupply(ids[i]);
        }
        return batchSupplies;
    }


    function uri(
        uint256 _id
    ) public view virtual override(ERC1155) returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return uris[_id];
    }



    /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
    function _exists(
        uint256 _id
    ) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
    function _getNextTokenID() private returns (uint256) {
        return _currentTokenID+=1;
    }

    /**
    * @dev increments the value of _currentTokenID
    */
    function _incrementTokenTypeId() private  {
        _currentTokenID++;
    }


  /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    * @param creator Creator's wallet address
    * @param price Price in ETH for this token type
    * @param _initialSupply amount to supply the first owner
    * @param _uri  URI for this token type
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
    function create(
        address creator,
        uint256 price,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external onlyOwner returns (uint256) {
        require(price > 0, "Price must be greater than zero");
        require(bytes(_uri).length > 0, "Invalid URI");
        require(creator != address(0), "Invalid creator address");
        require(_initialSupply > 0, "Initial supply must be greater than zero");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;
        if (splitters[creators[_id]] == address(0)) {
            generateSplitter(creator, address(this));
        }
        emit URI(_uri, _id);
        _mint(address(this), _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        prices[_id] = price;
        uris[_id] = _uri;
        return _id;
  }

    function buyTokens(uint256 _id, uint256 _amount) public payable {
        require(_exists(_id), "Token doesn't exist");
        require(_amount <= balanceOf(address(this), _id), "Insufficient balance for token");
        require(msg.value >= _amount * prices[_id], "Insufficient ETH amount to buy this tokens");
        _safeTransferFrom(address(this), _msgSender(), _id, _amount, "0x0");
        (bool sent, ) = payable(splitters[creators[_id]]).call{value: _amount * prices[_id], gas: 100000}("");
        require(sent, "Failed to send change");
        uint256 change;
        if (msg.value >= _amount * prices[_id]) {
            change = msg.value - _amount * prices[_id];
            (sent, ) = payable(_msgSender()).call{value: change, gas: 100000}("");
            require(sent, "Failed to send change");
        }


    }

    function generateSplitter(address _creator, address _contract) internal {
        SplitterUpgradeable splitterContract = new SplitterUpgradeable();
        splitterContract.initialize(_creator, _contract, royalty);
        splitters[_creator] = address(splitterContract);
        emit SplitterCreated(_creator, address(splitterContract));
    }


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


    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        require(_exists(_tokenId), "Token doesn't exist");
        uint256 royaltyAmount = (_salePrice * royalty) / 100;
        return (splitters[creators[_tokenId]], royaltyAmount);
    }


    function getRaribleV2Royalties(uint256 id) override public view returns (LibPart.Part[] memory) {
        require(_exists(id), "Token doesn't exist");
        LibPart.Part[] memory result = new LibPart.Part[](1);

        LibPart.Part memory _r = LibPart.Part({
                                    account: payable(splitters[creators[id]]),
                                    value: uint96(royalty)
                                });
        result[0] = _r;
        return result;
    }


    function getFeeRecipients(uint256 id) public override view returns (address payable[] memory) {
        require(_exists(id), "Token doesn't exist");
        address payable[] memory result = new address payable[](1);
        result[0] = payable(splitters[creators[id]]);
        return result;
    }

    function getFeeBps(uint256 id) public override view returns (uint[] memory) {
        require(_exists(id), "Token doesn't exist");
        uint[] memory result = new uint[](1);
        result[0] = royalty;
        return result;
    }



}