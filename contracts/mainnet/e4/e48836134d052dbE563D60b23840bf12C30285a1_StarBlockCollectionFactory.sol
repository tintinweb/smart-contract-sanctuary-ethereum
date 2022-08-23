// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: MIT
// StarBlock Contracts, more: https://www.starblock.io/

pragma solidity ^0.8.10;

//import "erc721a/contracts/extensions/ERC721AQueryable.sol";
//import "@openzeppelin/contracts/token/common/ERC2981.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./ERC721AQueryable.sol";
import "./ERC2981.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Metadata.sol";

interface IStarBlockCollection is IERC721AQueryable, IERC2981 {
    struct SaleConfig {
        uint256 startTime;// 0 for not set
        uint256 endTime;// 0 for will not end
        uint256 price;
        uint256 maxAmountPerAddress;// 0 for not limit the amount per address
    }

    event UpdateWhitelistSaleConfig(SaleConfig _whitelistSaleConfig);
    event UpdateWhitelistSaleEndTime(uint256 _oldEndTime, uint256 _newEndTime);
    event UpdatePublicSaleConfig(SaleConfig _publicSaleConfig);
    event UpdatePublicSaleEndTime(uint256 _oldEndTime, uint256 _newEndTime);
    event UpdateChargeToken(IERC20 _chargeToken);

    function supportsInterface(bytes4 _interfaceId) external view override(IERC165, IERC721A) returns (bool);
    
    function maxSupply() external view returns (uint256);
    function exists(uint256 _tokenId) external view returns (bool);
    
    function maxAmountForArtist() external view returns (uint256);
    function artistMinted() external view returns (uint256);

    function chargeToken() external view returns (IERC20);

    // function whitelistSaleConfig() external view returns (SaleConfig memory);
    function whitelistSaleConfig() external view 
            returns (uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _maxAmountPerAddress);
    function whitelist(address _user) external view returns (bool);
    function whitelistAllowed(address _user) external view returns (uint256);
    function whitelistAmount() external view returns (uint256);
    function whitelistSaleMinted(address _user) external view returns (uint256);

    // function publicSaleConfig() external view returns (SaleConfig memory);
    function publicSaleConfig() external view 
            returns (uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _maxAmountPerAddress);
    function publicSaleMinted(address _user) external view returns (uint256);

    function userCanMintTotalAmount() external view returns (uint256);

    function whitelistMint(uint256 _amount) external payable;
    function publicMint(uint256 _amount) external payable;
}

//The ERC721 collection for Artist on StarBlock NFT Marketplace, the owner is Artist and the protocol fee is for StarBlock.
contract StarBlockCollection is IStarBlockCollection, ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    uint256 public immutable maxSupply;
    string private baseTokenURI;

    uint256 public immutable maxAmountForArtist;
    uint256 public artistMinted;// the total minted amount for artist by artistMint method

    IERC20 public chargeToken;// the charge token for mint, zero for ETH

    address payable public protocolFeeReceiver;// fee receiver address for protocol
    uint256 public protocolFeeNumerator; // div _feeDenominator()(is 10000) is the real ratio

    SaleConfig public whitelistSaleConfig;
    mapping(address => bool) public whitelist;// whitelists
    mapping(address => uint256) public whitelistAllowed;// whitelists and allowed amount
    uint256 public whitelistAmount;
    mapping(address => uint256) public whitelistSaleMinted;

    //public mint config
    SaleConfig public publicSaleConfig;
    mapping(address => uint256) public publicSaleMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "StarBlockCollection: The caller is another contract");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        IERC20 _chargeToken,
        string memory _baseTokenURI,
        uint256 _maxAmountForArtist,
        address payable _protocolFeeReceiver, 
        uint256 _protocolFeeNumerator, 
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC721A(_name, _symbol) {
        require(_maxSupply > 0 && _maxAmountForArtist <= _maxSupply && _protocolFeeReceiver != address(0)
                 && _protocolFeeNumerator <= _feeDenominator() && _royaltyFeeNumerator <= _feeDenominator(), "StarBlockCollection: invalid parameters!");
        maxSupply = _maxSupply;
        chargeToken = _chargeToken;
        baseTokenURI = _baseTokenURI;
        maxAmountForArtist = _maxAmountForArtist;
        protocolFeeReceiver = _protocolFeeReceiver;
        protocolFeeNumerator = _protocolFeeNumerator;
        if(_royaltyReceiver != address(0)){
            _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        }
    }

    function whitelistMint(uint256 _amount) external payable callerIsUser {
        if(whitelistSaleConfig.maxAmountPerAddress == 0){
            require(whitelistAllowed[msg.sender] >= (whitelistSaleMinted[msg.sender] + _amount), "StarBlockCollection: whitelist reached allowed!");
        }else{
            require(whitelist[msg.sender], "StarBlockCollection: not in whitelist!");
        }
        _checkUserCanMint(whitelistSaleConfig, _amount, whitelistSaleMinted[msg.sender]);
        
        whitelistSaleMinted[msg.sender] += _amount;
        if(whitelistSaleConfig.price > 0 || (whitelistSaleConfig.price == 0 && msg.value > 0)){
            _charge(whitelistSaleConfig.price * _amount);
        }
        _safeMint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount) external payable callerIsUser {
        _checkUserCanMint(publicSaleConfig, _amount, publicSaleMinted[msg.sender]);

        publicSaleMinted[msg.sender] += _amount;
        if(publicSaleConfig.price > 0 || (publicSaleConfig.price == 0 && msg.value > 0)){
            _charge(publicSaleConfig.price * _amount);
        }
        _safeMint(msg.sender, _amount);
    }

    function artistMint(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "StarBlockCollection: amount should be greater than 0!");
        require((artistMinted + _amount) <= maxAmountForArtist, "StarBlockCollection: reached max amount for artist!");
        require((totalSupply() + _amount) <= maxSupply, "StarBlockCollection: reached max supply!");
        artistMinted += _amount;
        _safeMint(msg.sender, _amount);
    }

    function userCanMintTotalAmount() public view returns (uint256) {
        return maxSupply - (totalSupply() + maxAmountForArtist - artistMinted);
    }
    
    function _checkUserCanMint(SaleConfig memory _saleConfig, uint256 _amount, uint256 _mintedAmount) internal view {
        require(_amount > 0, "StarBlockCollection: amount should be greater than 0!");
        require(userCanMintTotalAmount() >= _amount, "StarBlockCollection: reached max supply!");
        require(_saleConfig.startTime > 0, "StarBlockCollection: sale has not set!");
        require(_saleConfig.startTime <= block.timestamp, "StarBlockCollection: sale has not started yet!");
        require(_saleConfig.endTime == 0 || _saleConfig.endTime >= block.timestamp, "StarBlockCollection: sale has ended!");
        require(_saleConfig.maxAmountPerAddress == 0 || (_mintedAmount + _amount) <= _saleConfig.maxAmountPerAddress, 
                "StarBlockCollection: reached max amount per address!");
    }

    function _charge(uint256 _amount) internal nonReentrant {
        bool success = true;
        uint256 shouldChargedETH;
        if(address(chargeToken) != address(0)){
            uint256 balance = chargeToken.balanceOf(msg.sender);
            require(balance >= _amount, "StarBlockCollection: not enough token!");
            chargeToken.safeTransferFrom(msg.sender, address(this), _amount);
        }else{
            require(msg.value >= _amount, "StarBlockCollection: not enough ETH!");
            shouldChargedETH = _amount;
        }
        if (msg.value > shouldChargedETH) {//return if over
            success = _transferETH(payable(msg.sender), msg.value - shouldChargedETH);
        }
        require(success, "StarBlockCollection: charge failed!");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IStarBlockCollection, ERC2981, ERC721A) returns (bool) {
        return _interfaceId == type(IStarBlockCollection).interfaceId 
                || _interfaceId == type(IERC721).interfaceId 
                || _interfaceId == type(IERC721Metadata).interfaceId 
                || _interfaceId == type(IERC721A).interfaceId 
                || _interfaceId == type(IERC721AQueryable).interfaceId 
                || ERC2981.supportsInterface(_interfaceId) 
                || ERC721A.supportsInterface(_interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner nonReentrant {
        baseTokenURI = _baseTokenURI;
    }

    function addWhitelists(address[] memory addresses) external onlyOwner nonReentrant {
        require(whitelistSaleConfig.startTime > 0 && whitelistSaleConfig.maxAmountPerAddress > 0, "StarBlockCollection: error whitelist sale config!");
        require(addresses.length > 0, "StarBlockCollection: addresses can not be empty!");
        for (uint256 i = 0; i < addresses.length; i++) {
            if(!whitelist[addresses[i]]){
                whitelist[addresses[i]] = true;
                whitelistAmount ++;
            }
        }
    }

    function removeWhitelists(address[] memory addresses) external onlyOwner nonReentrant {
        require(addresses.length > 0, "StarBlockCollection: addresses can not be empty!");
        for (uint256 i = 0; i < addresses.length; i++) {
            if(whitelist[addresses[i]]){
                whitelist[addresses[i]] = false;
                whitelistAmount --;
            }
        }
    }

    function setWhitelistAllowed(address[] memory addresses, uint256[] memory allowedAmounts) external onlyOwner nonReentrant {
        require(whitelistSaleConfig.startTime > 0 && whitelistSaleConfig.maxAmountPerAddress == 0, "StarBlockCollection: error whitelist sale config!");
        require(addresses.length > 0 && addresses.length == allowedAmounts.length, "StarBlockCollection: error parameters!");
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            uint256 amount = allowedAmounts[i];
            if(amount > 0){
                if(whitelistAllowed[addr] == 0){
                    whitelistAmount ++;
                }
                whitelistAllowed[addr] = amount;
            }
        }
    }

    function removeWhitelistAllowed(address[] memory addresses) external onlyOwner nonReentrant {
        require(addresses.length > 0, "StarBlockCollection: error parameters!");
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if(whitelistAllowed[addr] > 0){
                whitelistAllowed[addr] = 0;
                whitelistAmount --;
            }
        }
    }

    function setInfo(IERC20 _chargeToken, SaleConfig memory _whitelistSaleConfig, 
                    SaleConfig memory _publicSaleConfig, 
                    address _royaltyReceiver, uint96 _royaltyFeeNumerator) external onlyOwner nonReentrant {
        updateChargeToken(_chargeToken);
        updateWhitelistSaleConfig(_whitelistSaleConfig);
        updatePublicSaleConfig(_publicSaleConfig);
        if(_royaltyReceiver != address(0)){
            _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        }
    }

    function _checkSaleConfig(SaleConfig memory _saleConfig) internal pure returns (bool) {
        return (_saleConfig.startTime == 0 || (_saleConfig.endTime == 0 || (_saleConfig.startTime < _saleConfig.endTime)));
    }

    function updateWhitelistSaleConfig(SaleConfig memory _whitelistSaleConfig) public onlyOwner {
        require(whitelistSaleConfig.startTime == 0 || whitelistSaleConfig.startTime > block.timestamp, "StarBlockCollection: can only change the unstarted sale config!");
        require(_whitelistSaleConfig.startTime == 0 || _whitelistSaleConfig.startTime > block.timestamp, "StarBlockCollection: the new config should not be started!");
        require(_whitelistSaleConfig.startTime < (block.timestamp + 180 days), "StarBlockCollection: start time should be within 180 days!");
        require(_whitelistSaleConfig.endTime < (block.timestamp + 900 days), "StarBlockCollection: end time should be within 900 days!");
        require(_checkSaleConfig(_whitelistSaleConfig), "StarBlockCollection: invalid parameters!");
        
        whitelistSaleConfig.startTime = _whitelistSaleConfig.startTime;
        whitelistSaleConfig.endTime = _whitelistSaleConfig.endTime;
        whitelistSaleConfig.price = _whitelistSaleConfig.price;
        whitelistSaleConfig.maxAmountPerAddress = _whitelistSaleConfig.maxAmountPerAddress;

        emit UpdateWhitelistSaleConfig(_whitelistSaleConfig);
    }

    function updateWhitelistSaleEndTime(uint256 _newEndTime) external onlyOwner nonReentrant {
        require(whitelistSaleConfig.startTime > 0 && whitelistSaleConfig.startTime < _newEndTime, "StarBlockCollection: the new end time should be greater than start time!");
        whitelistSaleConfig.endTime = _newEndTime;
        emit UpdateWhitelistSaleEndTime(whitelistSaleConfig.endTime, _newEndTime);
    }

    function updatePublicSaleConfig(SaleConfig memory _publicSaleConfig) public onlyOwner {
        require(publicSaleConfig.startTime == 0 || publicSaleConfig.startTime > block.timestamp, "StarBlockCollection: can only change the unstarted sale config!");
        require(_publicSaleConfig.startTime == 0 || _publicSaleConfig.startTime > block.timestamp, "StarBlockCollection: the new config should not be started!");
        require(_publicSaleConfig.startTime < (block.timestamp + 180 days), "StarBlockCollection: start time should be within 180 days!");
        require(_publicSaleConfig.endTime < (block.timestamp + 900 days), "StarBlockCollection: end time should be within 900 days!");
        require(_checkSaleConfig(_publicSaleConfig), "StarBlockCollection: invalid parameters!");

        publicSaleConfig.startTime = _publicSaleConfig.startTime;
        publicSaleConfig.endTime = _publicSaleConfig.endTime;
        publicSaleConfig.price = _publicSaleConfig.price;
        publicSaleConfig.maxAmountPerAddress = _publicSaleConfig.maxAmountPerAddress;

        emit UpdatePublicSaleConfig(_publicSaleConfig);
    }

    function updatePublicSaleEndTime(uint256 _newEndTime) external onlyOwner nonReentrant {
        require(publicSaleConfig.startTime > 0 && publicSaleConfig.startTime < _newEndTime, "StarBlockCollection: the new end time should be greater than start time!");
        publicSaleConfig.endTime = _newEndTime;
        emit UpdatePublicSaleEndTime(publicSaleConfig.endTime, _newEndTime);
    }

    function updateChargeToken(IERC20 _chargeToken) public onlyOwner {
        require(whitelistSaleConfig.startTime == 0 || whitelistSaleConfig.startTime > block.timestamp, "StarBlockCollection: whitelist sale has started!");
        require(publicSaleConfig.startTime == 0 || publicSaleConfig.startTime > block.timestamp, "StarBlockCollection: public sale has started!");
        chargeToken = _chargeToken;
        emit UpdateChargeToken(_chargeToken);
    }

    function updateProtocolFeeReceiverAndNumerator(address payable _protocolFeeReceiver, uint256 _protocolFeeNumerator) external nonReentrant {
        require(msg.sender == protocolFeeReceiver, "StarBlockCollection: only protocolFeeReceiver can set!");
        require(_protocolFeeReceiver != address(0), "StarBlockCollection: _protocolFeeReceiver can not be zero!");
        require(_protocolFeeNumerator <= protocolFeeNumerator, "StarBlockCollection: can only set lower protocol fee numerator!");
        protocolFeeReceiver = _protocolFeeReceiver;
        protocolFeeNumerator = _protocolFeeNumerator;
    }

    function withdrawMoney() external onlyOwner {
        uint256 revenue = _getRevenueAmount();
        uint256 artistRevenue = revenue;
        uint256 protocolFee = 0;
        if(protocolFeeNumerator > 0 && revenue > 0){
            protocolFee = revenue * protocolFeeNumerator / _feeDenominator();
            artistRevenue = revenue - protocolFee;
        }
        bool success = false;
        if(artistRevenue > 0){
            success = _transferRevenue(payable(owner()), artistRevenue);
        }
        if(success && protocolFee > 0){
            success = _transferRevenue(protocolFeeReceiver, protocolFee);
        }
        require(success, "StarBlockCollection: withdrawMoney failed!");
    }

    function _getRevenueAmount() internal view returns (uint256 _amount){
        if(address(chargeToken) != address(0)){
            _amount = chargeToken.balanceOf(address(this));
        }else{
            _amount = address(this).balance;
        }
    }

    function _transferRevenue(address payable _user, uint256 _amount) internal nonReentrant returns (bool _success) {
        if(address(chargeToken) != address(0)){
            chargeToken.safeTransfer(_user, _amount);
            _success = true;
        }else{
            _success = _transferETH(_user, _amount);
        }
    }

    function _transferETH(address payable _user, uint256 _amount) internal returns (bool _success) {
        (_success, ) = _user.call{value: _amount}("");
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner nonReentrant {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner nonReentrant {
        _deleteDefaultRoyalty();
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }
}

interface IStarBlockCollectionFactory {
    event CollectionDeployed(IStarBlockCollection _collection, address _user, string _uuid);

    function collections(IStarBlockCollection _collection) external view returns (address);
    function collectionsAmount() external view returns (uint256);

    function collectionProtocolFeeReceiver() external view returns (address payable);
    function collectionProtocolFeeNumerator() external view returns (uint256);

    function deployCollection(
            string memory _uuid,
            string memory _name,
            string memory _symbol,
            uint256 _maxSupply,
            IERC20 _chargeToken,
            string memory _baseTokenURI,
            uint256 _maxAmountForArtist,
            address _royaltyReceiver,
            uint96 _royaltyFeeNumerator
    ) external returns (IStarBlockCollection _collection);
}

contract StarBlockCollectionFactory is IStarBlockCollectionFactory, Ownable, ReentrancyGuard {
    uint256 public constant FEE_DENOMINATOR = 10000;

    mapping(IStarBlockCollection => address) public collections;
    uint256 public collectionsAmount;

    address payable public collectionProtocolFeeReceiver; 
    uint256 public collectionProtocolFeeNumerator; //should less than FEE_DENOMINATOR

    constructor(
        address payable _collectionProtocolFeeReceiver, 
        uint256 _collectionProtocolFeeNumerator
    ) {
        require(_collectionProtocolFeeReceiver != address(0) && _collectionProtocolFeeNumerator <= FEE_DENOMINATOR, 
                "StarBlockCollectionFactory: invalid parameters!");
        collectionProtocolFeeReceiver = _collectionProtocolFeeReceiver;
        collectionProtocolFeeNumerator = _collectionProtocolFeeNumerator;
    }

    function deployCollection(
            string memory _uuid,
            string memory _name,
            string memory _symbol,
            uint256 _maxSupply,
            IERC20 _chargeToken,
            string memory _baseTokenURI,
            uint256 _maxAmountForArtist,
            address _royaltyReceiver,
            uint96 _royaltyFeeNumerator
    ) external nonReentrant returns (IStarBlockCollection _collection) {
        _collection = new StarBlockCollection(_name, _symbol, _maxSupply, _chargeToken, _baseTokenURI, 
                        _maxAmountForArtist, collectionProtocolFeeReceiver, collectionProtocolFeeNumerator, 
                        _royaltyReceiver, _royaltyFeeNumerator);
        Ownable(address(_collection)).transferOwnership(msg.sender);
        collections[_collection] = msg.sender;
        collectionsAmount ++;
        emit CollectionDeployed(_collection, msg.sender, _uuid);
    }
    
    function updateCollectionProtocolFeeReceiverAndNumerator(address payable _collectionProtocolFeeReceiver, 
            uint256 _collectionProtocolFeeNumerator) external onlyOwner nonReentrant {
        require(_collectionProtocolFeeReceiver != address(0), "StarBlockCollectionFactory: _collectionProtocolFeeReceiver can not be zero!");
        require(_collectionProtocolFeeNumerator <= FEE_DENOMINATOR, "StarBlockCollectionFactory: _collectionProtocolFeeNumerator should not be greater than 10000!");
        collectionProtocolFeeReceiver = _collectionProtocolFeeReceiver;
        collectionProtocolFeeNumerator = _collectionProtocolFeeNumerator;
    }
}