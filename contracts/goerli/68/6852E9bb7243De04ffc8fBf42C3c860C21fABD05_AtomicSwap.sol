/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
pragma abicoder v2;

/**
* @dev Interface for chainlink price oracle 
*/
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

/**
* @dev Interface for Subscription contract.  Allows the contract to query the subscription
* status of an address
*/
interface ISUB{

  function isSubscriber(address _address, uint256 _vendorId) external view returns (bool);

}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
   
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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}

/**
* @dev chainlink price oracle to return ETH/USD price data
*/
abstract contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

     /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256, uint80) {
        (
            uint80 roundID, 
            int price,
            /* uint startedAt */,
            /* uint timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return (uint256(price), roundID);
    }

     /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709562301
     *    
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    function getHistoricalPrice(uint80 roundId) public view returns (uint256) {
        (
            /* uint80 id */, 
            int price,
            /* uint startedAt */,
            uint timeStamp,
            /* uint80 answeredInRound */
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return uint256(price);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

        /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

}


/**
* @dev AtomicSwap contract allows users to create many to many NFT swaps between two parties
* in a single atomic transaction. The contract supports the NFT ERC721 and ERC1155 standards 
* as well as the ability to send Ethereum as part of the contract. 
*/
contract AtomicSwap is Ownable, Pausable, PriceConsumerV3 {

    using SafeMath for uint;

    // Swap Status
    enum swapStatus { New, Opened, Closed, Cancelled }
    enum contractType { ERC721, ERC1155 }

    struct atomicSwapContract {
        address payable addressOne;
        uint256 valueOne;
        address payable addressTwo;
        uint256 valueTwo;
        bytes nonce;
        affiliateStruct affiliate;
        nftStruct nftsOne;
        nftStruct nftsTwo;
    }

    struct nftStruct {
        address[] contractAddress;
        uint256[] tokenId; 
        uint256[] amount;
        bytes[] data;
        contractType[] typeOf;
    }

    struct affiliateStruct {
        bytes32 code;
        address payable affiliateAddress;
        uint256 percent;
    }

    mapping(bytes32 => swapStatus) public swapContract;  
    mapping(bytes32 => uint256) public _feePaid; 
 
    uint256 public _ethFee;
    uint256 public _usdFee;
    uint256 public _pendingFee;
    uint256 public _feeBalance;
    bool public _chainLink;
   
    address public _subscribeContract;
    address payable public _nefster;
   

    event paymentReceived(address indexed payer, uint256 value);
    event swapCreated(bytes32 contractId);
    event swapClosed(bytes32 contractId);
    event swapCanceled(bytes32 contractId);
    event feeTransfer(uint256 amount);
    event payAffiliate(bytes32 code, address indexed affiliateAddress, uint256 amount);

    string public constant name = "AtomicSwap";
    string public constant version = "1.0";
    string public constant codename = "Nefster";

    constructor()  {

    }
 
    receive() external payable { 
        _feeBalance = _feeBalance.add(msg.value);
        emit paymentReceived(msg.sender, msg.value);
    }

    /** 
    * @dev Create the atomic swap contract & return the contractId
    */
    function createAtomicSwap(atomicSwapContract memory _contract, uint256 _vendorId, uint80 _roundId) payable public whenNotPaused returns(bytes32) {
        uint256 swapFee = getSwapFee(msg.sender, _vendorId, _roundId);
        require(msg.value >= _contract.valueOne.add(swapFee), "AtomicSwap: not enough eth sent for this transaction");
        require(msg.sender == _contract.addressOne, "AtomicSwap: nft holder address does not match contract");
        // pending fee is refundable if the contract is cancelled
        _pendingFee = _pendingFee.add(swapFee);
        // get a new contract id 
        bytes32 _contractId = getContractId(_contract);
        // swap fee paid for this contract
        _feePaid[_contractId] = swapFee;
        // make sure this contract is new
        require(swapContract[_contractId] == swapStatus.New, "AtomicSwap: contract already exists");
        swapContract[_contractId] = swapStatus.Opened;
        emit swapCreated(_contractId);
        return _contractId;
    }

    /**
    * @dev internal function to calculate contract hash. Returns unique id per contract 
    */
    function getContractId(atomicSwapContract memory _contract) internal pure returns(bytes32) {
        return keccak256(abi.encode(_contract));
    }

    /**
    * @dev Close the atomic swap contract
    */
    function closeAtomicSwap(atomicSwapContract memory _contract, bytes32 _contractId, uint256 _vendorId, uint80 _roundId) payable public whenNotPaused {
        uint256 swapFee = getSwapFee(msg.sender, _vendorId, _roundId);
        require(msg.value >= _contract.valueTwo.add(swapFee), "AtomicSwap: not enough eth sent for this transaction");
        require(_contractId == getContractId(_contract), "AtomicSwap: contract hash is not valid");
        require(msg.sender == _contract.addressTwo, "AtomicSwap: address does not match this contract");
        require(swapContract[_contractId] == swapStatus.Opened, "AtomicSwap: contract is no longer valid");
        
        // move the pending fee to contract fee balance
        _pendingFee = _pendingFee.sub(_feePaid[_contractId]);
        // check for affiliate 
        if (_contract.affiliate.code != 0 
                                     && _contract.affiliate.affiliateAddress != address(0) 
                                     && _contract.affiliate.percent > 0
                                     && swapFee > 0){
            // calculate the affliate payout %
            uint256 payout = swapFee.div(100).mul(_contract.affiliate.percent);
            // house gets the rest
            uint256 house = swapFee.sub(payout);
            if (house > 0)
                _feeBalance = _feeBalance.add(house);
            // transfer the payout fee to the affliate address
            if (payout > 0) {
                _contract.affiliate.affiliateAddress.transfer(payout);
                emit payAffiliate(_contract.affiliate.code, _contract.affiliate.affiliateAddress, payout);
            }
            // update the contract swap fee with the create swap pending fee
            _feeBalance = _feeBalance.add(_feePaid[_contractId]);
        } else {
            // no affiliate, update the contract with the pending create fee + close swap fee
            _feeBalance = _feeBalance.add(swapFee.add(_feePaid[_contractId]));    
        }
       
        // do the eth transfers
        if (_contract.valueOne > 0) {
            _contract.addressTwo.transfer(_contract.valueOne);
        }
        if (_contract.valueTwo > 0) {
            _contract.addressOne.transfer(_contract.valueTwo);
        }
        // do the nft transfers 
        for(uint i=0; i < _contract.nftsTwo.contractAddress.length; i++) {
            if (_contract.nftsTwo.typeOf[i] == contractType.ERC721)
                IERC721(_contract.nftsTwo.contractAddress[i])
                .safeTransferFrom(_contract.addressTwo, 
                                  _contract.addressOne, 
                                  _contract.nftsTwo.tokenId[i],
                                  _contract.nftsTwo.data[i]);
            else
                IERC1155(_contract.nftsTwo.contractAddress[i])
                .safeTransferFrom(_contract.addressTwo, 
                                  _contract.addressOne, 
                                  _contract.nftsTwo.tokenId[i],
                                  _contract.nftsTwo.amount[i],
                                  _contract.nftsTwo.data[i]);
        }
        for(uint i=0; i < _contract.nftsOne.contractAddress.length; i++) {
             if (_contract.nftsOne.typeOf[i] == contractType.ERC721)
                IERC721(_contract.nftsOne.contractAddress[i])
                .safeTransferFrom(_contract.addressOne, 
                                  _contract.addressTwo, 
                                  _contract.nftsOne.tokenId[i],
                                  _contract.nftsOne.data[i]);
            else
                IERC1155(_contract.nftsOne.contractAddress[i])
                .safeTransferFrom(_contract.addressOne, 
                                  _contract.addressTwo, 
                                  _contract.nftsOne.tokenId[i],
                                  _contract.nftsOne.amount[i],
                                  _contract.nftsOne.data[i]);
        }
        swapContract[_contractId] = swapStatus.Closed;
        emit swapClosed(_contractId);
    }

    /**
     * @dev Cancel the atomic swap contract
     */ 
    function cancelAtomicSwap(bytes32 _contractId, atomicSwapContract memory _contract) public {
        require(_contractId == getContractId(_contract), "AtomicSwap: contract hash is not valid");
        require(msg.sender == _contract.addressOne, "AtomicSwap: invalid address - must be swap creator");
        require(swapContract[_contractId] == swapStatus.Opened, "AtomicSwap: contract is no longer open");
        // cancel the contract
        swapContract[_contractId] = swapStatus.Cancelled;
        // refund the fee paid 
        _pendingFee = _pendingFee.sub(_feePaid[_contractId]);
        // refund any crypto to swap creator - addressOne
        if(_contract.valueOne > 0){
            _contract.addressOne.transfer(_contract.valueOne.add(_feePaid[_contractId]));
        } else if (_feePaid[_contractId] > 0){
            _contract.addressOne.transfer(_feePaid[_contractId]);
        }
        emit swapCanceled(_contractId); 
    }

    /**
     * @dev Set the masterfu address for fee payouts 
     */
    function setNefster(address payable _address) public onlyOwner {
      require(_address != address(0), "AtomicSwap: zero address");
      _nefster = _address;
    }

    /**
     * @dev Set the swap fee rate in wei
     */
    function setEthFee(uint256 _fee) public onlyOwner {
      _ethFee = _fee;
    }

    /**
     * @dev Set the swap fee rate in usd
     */
    function setUsdFee(uint256 _fee) public onlyOwner {
      _usdFee = _fee;
    }

      /**
     * @dev Set the chainLink flag
     */
    function setChainLink(bool _value) public onlyOwner {
      _chainLink = _value;
    }

    /**
    * @dev set the external subscription contract address and vendorId
    */
    function setSubContract(address _address) public onlyOwner {
        _subscribeContract = _address;
    }

    /**
    * @dev get the swap fee rate. calls external subscribe contract method isSubscriber
    * The swap fee for subscribers is zero.  For non-subscribers, return the _usdFee in ETH using the chainLink
    * price oracle when the _chainLink flag is true and _ethPrice when false;
    */
    function getSwapFee(address _address, uint256 _vendorId, uint80 _roundID) public view returns (uint256) {
        // create interface tp subscribe contract
        ISUB SubContract = ISUB(_subscribeContract);
        // call the external contract
        bool result = SubContract.isSubscriber(_address, _vendorId);
        if (result) {
            // subscriber 
            return 0;
        } 
        if (_chainLink){
            // non subscriber
            return getUsdFee(_roundID);
        }
        // fallback to eth fee
        return _ethFee;
    }


    /**
     * @dev returns the _usdFee in ETH 
     * calls chainlink price oracle 
     * @param _roundID  the roundID value returned from Chainlink getHistoricalPrice
     * @return uint256 
     */
    function getUsdFee(uint80 _roundID) public view returns (uint256) {
      // get eth price from chainlink oracle 
      uint256 price = getHistoricalPrice(_roundID);
      return (1 ether / price.div(100000000)).mul(_usdFee);
    }


    /** 
     * @dev Returns the contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Admin function to widthdraw eth fees collected 
     */
    function transferFees(uint256 _amount) public returns(uint256) {
        require(msg.sender == _nefster, "AtomicSwap: only nefster can do this");
        require(_amount <= _feeBalance, "AtomicSwap: amount not available");
        _feeBalance = _feeBalance.sub(_amount);
        _nefster.transfer(_amount);
        emit feeTransfer(_amount);
        return _amount;
    }

    /** 
     * @dev pause the contract
     */
    function pause(bool val) public onlyOwner {
        if (val) _pause();  else  _unpause();
    }

}