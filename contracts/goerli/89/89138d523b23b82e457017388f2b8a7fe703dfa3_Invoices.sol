/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: Desktop/Coding/meta4swap-contracts/invoices.sol


pragma solidity ^0.8.7;



contract Invoices is Ownable {

    uint256 public invoiceCount;
    uint256 public fee; //2.5 == 250
    
    address public admin;
    address public oracle;

    struct Invoice {
        string metadata;
        bool open;
        uint256 price;
        uint256 oraclePrice;
        uint256 created;
        uint256 closed;
        bool paid;
        address creator;
    }

    mapping(uint256 => Invoice) public invoices; // invoiceId => Invoice

    constructor(address _oracle) {
        fee = 100;
        oracle = _oracle;
    }

    event InvoiceCreated(
        uint256 invoiceId,
        address creator,
        string metadata
    );
    event InvoiceUpdated(
        uint256 invoiceId
    );
    event InvoicePaid(
        uint256 invoiceId
    );

    modifier onlyCreator(uint256 _invoiceId) {
        require(
            invoices[_invoiceId].creator == msg.sender ,
            "Not authorized. Creator only."
        );
        _;
    }

    function create(
        string memory _metadata,
        uint256 _price //in USD
    ) public returns (uint256) {

        invoiceCount++;

        Invoice memory _invoice;

        _invoice.metadata = _metadata;
        _invoice.price = _price;
        _invoice.creator = msg.sender;
        _invoice.open = true;
        _invoice.created = block.number;

        invoices[invoiceCount] = _invoice;

        emit InvoiceCreated(
            invoiceCount,
            _invoice.creator,
            _invoice.metadata
        );

        return invoiceCount;
    }

    function pay(uint256 _invoiceId)
        public
        payable
    {
        require(
            invoices[_invoiceId].open == true,
            "Invoice not open."
        );


        invoices[_invoiceId].oraclePrice = uint256(getLatestPrice());

        uint256 invoiceTotal = ((invoices[_invoiceId].price / invoices[_invoiceId].oraclePrice) *
            10**8);
        uint256 invoiceFee = (fee * invoiceTotal) / 10000;

        require(msg.value >= invoiceTotal, "Amount paid is less than total");

        invoices[_invoiceId].paid = true;
        invoices[_invoiceId].open = false;
        invoices[_invoiceId].closed = block.number;
        

        if (msg.value > invoiceTotal) {
            //send refund back to the user
            (bool sent,) = msg.sender.call{
                value: (msg.value - invoiceTotal)
            }("");
            require(sent, "Failed to Send Extra Ether back to Payer");
        }

        //pay creator
        (bool sent2,) = invoices[_invoiceId].creator.call{
            value: (invoiceTotal)
            }("");
        require(sent2, "Failed to Send Ether to Invoice Creator");

        //pay fee
        (bool sent3,) = owner().call{
            value: (invoiceFee)
            }("");
        require(sent3, "Failed to Send Ether fee to Contract Owner");


        emit InvoicePaid(
            _invoiceId
        );


    }

    //edit Settings
    //update fee
    function updateFee(uint256 _fee) public onlyOwner returns (bool) {
        fee = _fee;
        return true;
    }

    //update oracle address
    function updateOracle(address _oracle)
        public
        onlyOwner
        returns (bool)
    {
        oracle = _oracle;
        return true;
    }

    //edit Invoice
    function editPrice(uint256 _invoiceId, uint256 _price) public onlyCreator(_invoiceId) {
        invoices[_invoiceId].price = _price;
        emit InvoiceUpdated(_invoiceId);
    }

    function editMetadata(uint256 _invoiceId, string memory _metadata) public onlyCreator(_invoiceId) {
        invoices[_invoiceId].metadata = _metadata;
        emit InvoiceUpdated(_invoiceId);
    }

    function editState(uint256 _invoiceId, bool _open) public onlyCreator(_invoiceId) {
        invoices[_invoiceId].open = _open;
        emit InvoiceUpdated(_invoiceId);
    }

    //get Native Asset Price from Chain Link Oracle
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = AggregatorV3Interface(oracle).latestRoundData();
        // eth goerli 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        return price;
    }
}