/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-12
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/datastorage.sol


pragma solidity 0.8.14;


contract DataStorage is Ownable{
    uint16 public nftCommission; // applies to all NFTs - Paid by Seller
    uint16 public platformCommission; //  applies to all NFTs - Paid by Buyer
    address erc1155SaleMarket;
    address marketplace;

    event RoyaltyEvent(
        address nftContract,
        uint256 tokenId,
        address royaltyOwner,
        uint256 royaltyPercentage
    );

    struct Royalty {
        address royaltyOwner;
        uint256 royaltyPercentage;
        bool activated;
    }

    struct Affiliate {
        uint16 feePercent;
        address affiliateAddr;
    }

    // keeps account of all Royalty data 
    mapping(address => mapping(uint256 => Royalty)) public nftRoyalty;
    // keeps account of all commission charges
    mapping(address => Affiliate[3]) public sellerCommission;

    constructor(address _erc1155SaleMarket, address _marketplace ){
        erc1155SaleMarket = _erc1155SaleMarket;
        marketplace= _marketplace;
    }

    function setBatchRoyaltyData(
        address[] memory _nftContractAddress,
        uint256[] memory _tokenId,
        uint256[] memory _royaltyPercentage,
        address[] memory _royaltyOwner
    ) public onlyOwner {
        for(uint i=0; i<_royaltyOwner.length; i++) {
            Royalty storage _royalty;
            _royalty = nftRoyalty[_nftContractAddress[i]][_tokenId[i]];
            _royalty.royaltyOwner = _royaltyOwner[i];
            _royalty.royaltyPercentage = _royaltyPercentage[i];
            _royalty.activated = true;
        }
    }

    function setRoyaltyData(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        address _royaltyOwner
    ) external {
        require(msg.sender == erc1155SaleMarket || msg.sender == marketplace, "UNAUTORIZED");
        require(_royaltyPercentage <=2500, "ROYALTY_PERCENTAGE_EXCEEDED");
        Royalty storage _royalty;
        _royalty = nftRoyalty[_nftContractAddress][_tokenId];
        _royalty.royaltyOwner = _royaltyOwner;
        _royalty.royaltyPercentage = _royaltyPercentage;
        _royalty.activated = false;
        emit RoyaltyEvent(_nftContractAddress, _tokenId, _royaltyOwner, _royaltyPercentage);
    }

    function editFees(
        address _artist,
        Affiliate[3] memory _a,
        uint16 _platformFee,
        uint16 _nftCommission
    ) external onlyOwner {
        
        // seller commission
        if(_a.length > 0){
            Affiliate[3] storage a = sellerCommission[_artist]; 
            for(uint8 i=0; i<3; i++){
                a[i].feePercent = _a[i].feePercent;
                a[i].affiliateAddr = _a[i].affiliateAddr;
            }
        }

        if (platformCommission != _platformFee) {
            platformCommission = _platformFee;
        }
        if (nftCommission != _nftCommission) {
            nftCommission = _nftCommission;
        }
    }

    function setInitData(address _marketplace, address _erc1155SaleMarket) external onlyOwner{
        marketplace = _marketplace;
        erc1155SaleMarket= _erc1155SaleMarket;
    }

    function activateRoyalty(address _nftContractAddress, uint _tokenId) external {
        require(msg.sender == erc1155SaleMarket || msg.sender == marketplace, "Only run on redeem");
        nftRoyalty[_nftContractAddress][_tokenId].activated= true;
    }

    function setRoyaltyPercentage(address _nftContractAddress, uint _tokenId, uint256 _newPercentage) external{
        require(msg.sender == erc1155SaleMarket || msg.sender == marketplace, "Only run on redeem");
        require(_newPercentage <=2500, "ROYALTY_PERCENTAGE_EXCEEDED");
        nftRoyalty[_nftContractAddress][_tokenId].royaltyPercentage= _newPercentage;
    }

    function getRoyaltyPercentage(address _nftContractAddress, uint _tokenId) external view returns (uint){
        return nftRoyalty[_nftContractAddress][_tokenId].royaltyPercentage;
    }

    function getRoyaltyOwner(address _nftContractAddress, uint _tokenId) external view returns (address){
        return nftRoyalty[_nftContractAddress][_tokenId].royaltyOwner;
    }

    function getSellerCommission(address _artist) public view returns(Affiliate[3] memory) {
        return sellerCommission[_artist];
    }

    function isActivated(address _nftContractAddress, uint _tokenId) external view returns (bool){
        return nftRoyalty[_nftContractAddress][_tokenId].activated;
    }

}