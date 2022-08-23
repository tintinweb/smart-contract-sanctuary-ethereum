/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity ^0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC1155 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _amount, uint256 indexed _id);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OuchiSecondarySales1155 is Ownable {
    using SafeMath for uint256;

    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;

    struct Offer {
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        address maker;
        uint256 updatedAt;
    }

    address public erc1155addr;
    address public paymentTokenAddr;
    mapping(uint256 => Offer) public offers; // index => offer
    uint256 public numOffers = 0;
    uint256 public royaltyBps = 250;
    address public beneficiary;
    mapping(address=> uint256[]) public offersByAddress;

    event SetPrice(uint256 indexed index, uint256 price, address indexed tokenOwner);
    event Purchase(uint256 indexed index, address indexed buyer, uint256 tokenId, uint256 quantity, uint256 price);
    event PutOffer(uint256 indexed index, address indexed maker, uint256 tokenId, uint256 quantity, uint256 price);
    event Cancel(uint256 indexed index); 

    modifier onlyHolder(uint256 _index){
        require(offers[_index].maker == msg.sender, "Need to be the owner of this offer.");
        _;
    }

    modifier isAvailable(uint256 _index, uint256 _quantity){
        require(offers[_index].quantity >= _quantity, "Not enogh tokens available for purchase.");
        _;
    }
    
    constructor(address _erc1155addr, address _paymentTokenAddr, address _beneficiary) {
        erc1155addr = _erc1155addr;
        paymentTokenAddr = _paymentTokenAddr;
        beneficiary = _beneficiary;
    }

    function putOffer(uint256 _tokenId, uint256 _quantity, uint256 _price) external returns(bool) {
        IERC1155(erc1155addr).safeTransferFrom(msg.sender, address(this), _tokenId,  _quantity, bytes(""));
        
        Offer memory newOffer = Offer(_tokenId, _quantity, _price, msg.sender, block.timestamp);
        offers[numOffers] = newOffer;

        uint256 index = numOffers;
        offersByAddress[msg.sender].push(index);
        numOffers = numOffers.add(1);

        emit PutOffer(index, msg.sender, newOffer.tokenId, newOffer.quantity, newOffer.price);
        
        return true;
    }

    function cancelOffer(uint256 _index) external onlyHolder(_index) returns(bool) {
        Offer memory offer = offers[_index];

        uint256 quantity = offer.quantity;
        IERC1155(erc1155addr).safeTransferFrom(address(this), offer.maker, offer.tokenId, quantity, bytes(""));

        offers[_index].quantity = 0;

        emit Cancel(_index);

        return true;
    }
    
    function setPrice(uint256 _index, uint256 _price) external onlyHolder(_index) returns(bool){
        offers[_index].price = _price;

        emit SetPrice(_index, _price, offers[_index].maker);
        return true;
    }
    
    function purchase(uint256 _index, uint256 _quantity) external isAvailable(_index, _quantity) returns(bool){
        Offer memory offer = offers[_index];

        uint256 payAmount = _quantity.mul(offer.price);
        uint256 royaltyFee = payAmount.mul(royaltyBps).div(10000);

        IERC20(paymentTokenAddr).transferFrom(msg.sender, offer.maker, payAmount.sub(royaltyFee));
        IERC20(paymentTokenAddr).transferFrom(msg.sender, beneficiary, royaltyFee);
        IERC1155(erc1155addr).safeTransferFrom(address(this), msg.sender, offer.tokenId, _quantity, bytes(""));
        
        offers[_index].quantity = offers[_index].quantity.sub(_quantity);

        emit Purchase(_index, msg.sender, offer.tokenId, _quantity, offer.price);
        
        return true;
    }

    function setRoyalty(uint256 _royaltyBps) external onlyOwner returns(bool) {
        royaltyBps = _royaltyBps;
        return true;
    }
    
    function numberOfOffers(address maker) public view returns(uint256){
        return offersByAddress[maker].length;
    }

  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4){
      return ERC1155_RECEIVED_VALUE;
  }

  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4){
      return ERC1155_RECEIVED_VALUE;
  }

}