// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

/**
 * @title DataBundler
 * @author Tranquil Flow
 * @dev A contract that can be used to create, purchase and view private data bundles
 * @dev Built for Oasis Network's Sapphire ParaTime
 */
contract DataBundlerFlat is Ownable {

    // Data Bundles Info
    DataPoints[] private dataBundle;
    struct DataPoints {
        uint cost;
        uint data1;
        string data2;
    }
    uint public totalDataBundles;
    string public dataBundleName;

    // Purchaser Info
    mapping(address => mapping(uint => bool)) purchasedBundles;

    // Creator Info
    address public fundsReceiver;

    // Events
    event dataBundleCreated(uint ID, uint value);
    event dataBundlePurchased(uint ID, uint value);

    constructor() {
        fundsReceiver = msg.sender;
        dataBundleName = "TestGameName";
    }

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Purchases a Data Bundle
    function buyDataBundle(uint ID) public payable {
        require(msg.value >= dataBundle[ID].cost, "Bundle costs more");
        (bool sent,) = fundsReceiver.call{value: dataBundle[ID].cost}("");
        require(sent, "Failed to send Ether");
        purchasedBundles[msg.sender][ID] = true;
        emit dataBundlePurchased(ID, msg.value);
    }

    /// @dev Views the information inside a Data Bundle
    function viewDataBundle(uint ID) public view returns(DataPoints memory) {
        //require(purchasedBundles[msg.sender][ID] = true, "Data Bundle not purchased");
        return dataBundle[ID];
    }

    function viewDataBundle2(uint ID) public view returns(
        uint,
        string memory
    ) {
        //require(purchasedBundles[msg.sender][ID] = true, "Data Bundle not purchased");
        return(
            dataBundle[ID].data1,
            dataBundle[ID].data2
        );
    }

    /*//////////////////////////////////////////////////////////////
                            GAME DEV FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Creates a Data Bundle for purchase
    function createDataBundle(
        uint _cost,
        uint _data1,
        string memory _data2
    ) external {
        dataBundle.push(
            DataPoints({
                cost: _cost,
                data1: _data1,
                data2: _data2
            })
        );
        totalDataBundles++;
        uint ID = dataBundle.length;
        emit dataBundleCreated(ID, dataBundle[ID].cost);
    }

    /// @dev Changes the address that receives ETH from purchases of Data Bundles
    function changeFundsReceiver(address _fundsReceiver) external {
        require(_fundsReceiver != 0x0000000000000000000000000000000000000000, "Cannot add null address");
        fundsReceiver = _fundsReceiver;
    }

}