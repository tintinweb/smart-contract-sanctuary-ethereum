pragma solidity 0.4.24;

import "./Chainlinked.sol";
import "./Ownable.sol";

/*
 * POC of Ocean / Chainlink Integration
 * by Ocean Protocol Team
 */

contract requestGCP is Chainlinked, Ownable {
  /*
   * global variables
   */
  uint256 constant private ORACLE_PAYMENT = 1 * LINK; // default price for each request
  mapping (bytes32 => uint256) public results;        // _requestId => result value

  /*
   * events
   */
  event requestCreated(address indexed requester,bytes32 indexed jobId, bytes32 indexed requestId);
  event requestFulfilled(bytes32 indexed _requestId, uint256 _data);
  event tokenWithdrawn(address indexed recepient, uint256 amount);
  event tokenDeposited(address indexed sender, uint256 amount);
  /*
   * constructor function
   */
  constructor(address oracleAddress) public {
    // Set the address for the LINK token for the Kovan network.
    setLinkToken(0x66ef1A6a318e4Ce655e7183aceF44268C3995F16);
    // Set the address of the oracle in Kovan network to create requests to.
    setOracle(oracleAddress);
  }

  /*
   * view functions to get internal information
   */

  function getChainlinkToken() public view returns (address) {
    return chainlinkToken();
  }

  function getOracle() public view returns (address) {
    return oracleAddress();
  }

  function getRequestResult(bytes32 _requestId) public view returns (uint256) {
    return results[_requestId];
  }

  /*
   * Create a request and send it to default Oracle contract
   */
  function createRequest(
    bytes32 _jobId,
    string _coin,
    string _market
  )
    public
    onlyOwner
    returns (bytes32 requestId)
  {
    // create request instance
    Chainlink.Request memory req = newRequest(_jobId, this, this.fulfill.selector);
    // fill in the pass-in parameters
    req.add("endpoint", "price");
    req.add("fsym", _coin);
    req.add("tsyms", _market);
    req.add("copyPath", _market);
    req.addInt("times", 100);
    // send request & payment to Chainlink oracle (Requester Contract sends the payment)
    requestId = chainlinkRequestTo(getOracle(), req, ORACLE_PAYMENT);
    // emit event message
    emit requestCreated(msg.sender, _jobId, requestId);
  }

  /*
   * callback function to keep the returned value from Oracle contract
   */
  function fulfill(bytes32 _requestId, uint256 _data)
    public
    recordChainlinkFulfillment(_requestId)
  {
    results[_requestId] = _data;
    emit requestFulfilled(_requestId, _data);
  }

  /*
   * withdraw the remaining LINK tokens from the contract
   */
  function withdrawTokens() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkToken());
    uint256 balance = link.balanceOf(address(this));
    require(link.transfer(msg.sender, balance), "Unable to transfer");
    emit tokenWithdrawn(msg.sender, balance);
  }

  /*
   * cancel the pending request
   */
  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
	onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }
}