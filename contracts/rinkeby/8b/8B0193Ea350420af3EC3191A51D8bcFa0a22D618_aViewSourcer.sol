/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

contract VRFRequestIDBase {
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


abstract contract VRFConsumerBase is VRFRequestIDBase {
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;
  uint256 private constant USER_SEED_PLACEHOLDER = 0;
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}
 
contract aViewSourcer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    address public operator;
    
    uint256 public randomResult;
    uint256 counter;
    mapping (uint256 => bytes32) public counter2Id;
    mapping (bytes32 => uint256) public Id2Value;
    // uint256[] public expandedValues;

    event RandomNumberGenarated(bytes32 indexed requestId);
    event OperatorChanged(address indexed from,address indexed to);

    

    constructor() 
        VRFConsumerBase
        (
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        operator = msg.sender;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

     modifier onlyOperator{
       require(msg.sender == operator,"only operator can do this");
       _;
     }

    function changeOperator(address newOperator) public onlyOperator{
      operator = newOperator;
      emit OperatorChanged(msg.sender,newOperator);
    }
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyOperator returns (bytes32 requestId){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId =  requestRandomness(keyHash, fee);
        counter2Id[counter] = requestId;
        counter++;
        return requestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // randomResult = (randomness%20) + 1;
        Id2Value[requestId] = randomness;
        emit RandomNumberGenarated(requestId);
    }
 
    function withdrawLink(address to , uint256 value) public {
        require(LINK.transfer(to, value), "Not enough LINK");
    }

    function getMyNumber(uint256 _counter) public view returns(uint256){
        bytes32 reqId = counter2Id[_counter];
        uint256 value = Id2Value[reqId];
        return value;
    }


    function CheckBalance() public view returns (uint256){
        uint256 Balance = LINK.balanceOf(address(this));
        return Balance;
     }    

     
}