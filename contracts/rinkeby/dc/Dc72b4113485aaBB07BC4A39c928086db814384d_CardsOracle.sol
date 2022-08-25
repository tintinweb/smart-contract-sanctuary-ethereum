// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IOracle.sol";

contract CardsOracle is IOracle {

    address public owner;
    uint256 public fee;
    uint32 public requestId;
    bool public stopped;
    mapping(uint32 => Request) public idToRequest;

    event OracleRequest(uint32 indexed requestid, bool shuffle, uint8 nrOfCards, address indexed sender, uint256 indexed timestamp); 
    event OracleFulfillment(uint32 indexed requestid, bytes2[] cards, address indexed sender, uint256 indexed timestamp); 

    modifier onlyOwner {
      require(msg.sender == owner, "Sender is not owner");
      _;
    }

    modifier notStopped {
      require(!stopped, "Oracle is stopped");
      _;
    }

    constructor() {
        owner = msg.sender;
        stopped = false;
        requestId = 1;
        fee = 0.001 * 10 ** 18; // 0.001 ETH
    }

    function receiveRequest(Request calldata _request) external payable notStopped returns (uint32){
        require(msg.value >= fee, "Please send more ETH");
        require(_request.nrOfCards > 0 && _request.nrOfCards < 53 && _request.cbClient != address(0) && _request.cbSelector != bytes4(0) && !_request.fulfilled, "Invalid input data");

        idToRequest[requestId] = _request;

        emit OracleRequest(requestId, _request.shuffle, _request.nrOfCards, msg.sender, block.timestamp); 
        return requestId++;
    }

    function fulfillRequest(uint32 _requestId, bytes2[] calldata _cards) notStopped onlyOwner external {
        Request storage request = idToRequest[_requestId];

        assert(request.cbClient != address(0));
        assert(!request.fulfilled);
        assert(_cards.length == request.nrOfCards);

        request.fulfilled = true;

        emit OracleFulfillment(_requestId, _cards, msg.sender, block.timestamp);
        (bool success, ) = request.cbClient.call(abi.encodeWithSelector(request.cbSelector, _requestId, _cards));
        require(success, "Couldn't fulfill request");
    }

    function toggleState() public onlyOwner {
        stopped = !stopped;
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function withdraw(address payable _to) external onlyOwner {
        (bool success,) = _to.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOracle {
    struct Request {
        uint8 nrOfCards;
        bool shuffle;
        address cbClient;
        bytes4 cbSelector;
        bool fulfilled;
    }
}