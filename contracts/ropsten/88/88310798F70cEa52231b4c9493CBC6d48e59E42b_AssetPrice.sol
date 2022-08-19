pragma solidity >= 0.5.0 < 0.6.0;

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
    constructor () internal { }

    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
import "./provableAPI_0.5.sol";

contract AssetPrice is usingProvable, Ownable  {

    uint public assetPriceUSD;
    string private API_URL;
    uint public stamp = 0;
    uint public period = 60 * 60;
    event LogNewDieselPrice(string price);
    event LogNewProvableQuery(string description);
    event updatePrice(uint256 date, uint256 price);

    constructor()
        public
    {
        OAR = OracleAddrResolverI(0x90A0F94702c9630036FB9846B52bf31A1C991a84);
        provable_setCustomGasPrice(5000000000);
    }

    function setAPIUrl(string memory _apiUrl) public onlyOwner{
        API_URL = _apiUrl;
     }

    function getAPIUrl() public view onlyOwner returns(string memory){
        return API_URL;
     }

    function setPeriod(uint _period) public onlyOwner{
        period = _period;
    }
    function getAssetPrice() external view returns(uint){
        return assetPriceUSD;
    }
    function setAssetPrice( uint _price) public {
        assetPriceUSD = _price;
        emit updatePrice(block.timestamp, assetPriceUSD);
    }
    function __callback(
        bytes32 _myid,
        string memory _result
    )
        public
    {
        require(msg.sender == provable_cbAddress());
        emit LogNewDieselPrice(_result);
        uint updatePrice = parseInt(_result, 2); // Let's save it as cents...
        setAssetPrice(updatePrice);
        // Now do something with the USD Diesel price...
    }

    function update()
        external
        payable
    {
        bytes memory tempEmptyStringTest = bytes(API_URL);
        require(tempEmptyStringTest.length > 0, "not set API_URL yet!");
        require(block.timestamp - stamp > period, "not expired yet! lol");
        stamp = block.timestamp;
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
        provable_query("URL", API_URL);
    }
    }