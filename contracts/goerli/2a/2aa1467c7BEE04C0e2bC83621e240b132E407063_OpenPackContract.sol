/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol


pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

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

// File: @chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol


pragma solidity ^0.8.0;



/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: open-booster.sol


pragma solidity ^0.8.13;




interface RomeCgBoosterPack { //CHANGE HERE
	function transferFrom(address, address, uint) external returns (bool); //from to amount
	function allowance(address, address) external returns (uint256); //owner, spender
}
interface RCGCharacterCardMinter {
    function safeMint(address, string[] memory) external; //Address - Random / Card Number
    function transferOwnership(address) external; //Change owner of minting contract if new PACKOPEN contract is deployed.
}
interface RCGCardURISetter1 {
    function setURI1(uint256) external returns (string memory); //Random / Card Number
}
//RCGCardURISetter1

contract OpenPackContract is VRFV2WrapperConsumerBase, ConfirmedOwner{

	event RequestFulfilled(uint256 requestId, uint256 randomNum1, uint256 randomNum2, uint256 randomNum3, uint256 randomNum4, uint256 randomNum5, uint256 randomNum6, uint256 randomNum7);
    
	//Pack Token Contract
	address internal RomeCgBoosterPackContractAddress = 0x3646d122335f75f0C0C2F389B11eE1fc0C407Cf2;
	RomeCgBoosterPack RomeCgBoosterPackContract = RomeCgBoosterPack(RomeCgBoosterPackContractAddress);
	
	//URI Setter 1 Contact
	address public RCGCardURISetter1ContractAddress = 0xE215318ba9D2FD96363253451611cC8dCE4F1d84;
    RCGCardURISetter1 RCGCardURISetter1Contract = RCGCardURISetter1(RCGCardURISetter1ContractAddress);
	
	//Character Card Minter Contract
    address internal RCGCharacterCardMinterAddress = 0x68aAE4a5054c064251507692bd9C0E02Dc2c8c63;
	RCGCharacterCardMinter RCGCharacterCardMinterContract = RCGCharacterCardMinter(RCGCharacterCardMinterAddress);
	
	address internal msgSender;
	uint256 internal packAllowance;
	uint256 public lastRequestID;
    
	
	//Mapped Random Numbers
	mapping(uint256 => uint256) public mapIdToWord1;
	mapping(uint256 => uint256) public mapIdToWord2;
	mapping(uint256 => uint256) public mapIdToWord3;
	mapping(uint256 => uint256) public mapIdToWord4;
	mapping(uint256 => uint256) public mapIdToWord5;
	mapping(uint256 => uint256) public mapIdToWord6;
	mapping(uint256 => uint256) public mapIdToWord7;
	//mapping(uint256 => uint256) public mapIdToWord8;
	//mapping(uint256 => uint256) public mapIdToWord9;
	//mapping(uint256 => uint256) public mapIdToWord10;
	mapping(uint256 => address) public mapIdToAddress; //Address to ID
	mapping(uint256 => bool) public mapIdToFulfilled; //Completion Status to ID
	
	//Array of URIs
	string[] public URIArray;
	
	//Might need to change this if the request is failing <----------------------------------------
	uint32 callbackGasLimit = 2420000; //Might need to change this if the request is failing <----------------------------------------
	//Might need to change this if the request is failing <----------------------------------------
	//800000
    uint16 requestConfirmations = 3;
    
    //Address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
 	//address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    
    constructor() ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) payable{
        //Set other variable here if you want.
    }
    
    function openPack() external payable {
        msgSender = msg.sender;

        //Check Allowance
		packAllowance = RomeCgBoosterPackContract.allowance(msg.sender, address(this));
		require (packAllowance >= 1000000000000000000, "You must approve this contract to spend your pack.");
		spendPackThenRequest(); 
    }
	function spendPackThenRequest() private{
		bool sT = false; //Successful Transfer
		sT = RomeCgBoosterPackContract.transferFrom(msg.sender, address(this), 1000000000000000000);
		
		if (sT){
            requestRandomWords();
        }
	}
	function requestRandomWords() private returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, 7);
    
        mapIdToAddress[requestId] = msg.sender;
        mapIdToFulfilled[requestId] = false;
        lastRequestID = requestId;
        return requestId;
    }
    
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
		require(mapIdToFulfilled[_requestId] == false, 'request fulfilled already');
		mapIdToFulfilled[_requestId] = true;
		mapIdToWord1[_requestId] = (_randomWords[0] % 1000) + 1;
		mapIdToWord2[_requestId] = (_randomWords[1] % 1000) + 1; //Store it.
		mapIdToWord3[_requestId] = (_randomWords[2] % 1000) + 1;
		mapIdToWord4[_requestId] = (_randomWords[3] % 1000) + 1;
		mapIdToWord5[_requestId] = (_randomWords[4] % 1000) + 1;
		mapIdToWord6[_requestId] = (_randomWords[5] % 1000) + 1;
		mapIdToWord7[_requestId] = (_randomWords[6] % 1000) + 1;
		//mapIdToWord8[_requestId] = flatRanNum8; //Store it.
		//mapIdToWord9[_requestId] = flatRanNum9; //Store it.
		//mapIdToWord10[_requestId] = flatRanNum10; //Store it.
		
		mintCards(_requestId);
		emit RequestFulfilled(_requestId, mapIdToWord1[_requestId], mapIdToWord2[_requestId], mapIdToWord3[_requestId], mapIdToWord4[_requestId], mapIdToWord5[_requestId], mapIdToWord6[_requestId], mapIdToWord7[_requestId]); //ID, NUM1, NUM2
    }
    function mintCards(uint256 _requestId) private{
		delete URIArray;
		URIArray.push(RCGCardURISetter1Contract.setURI1(mapIdToWord1[_requestId]));
		URIArray.push(RCGCardURISetter1Contract.setURI1(mapIdToWord2[_requestId]));
		URIArray.push(RCGCardURISetter1Contract.setURI1(mapIdToWord3[_requestId]));
		URIArray.push(RCGCardURISetter1Contract.setURI1(mapIdToWord4[_requestId]));
		URIArray.push(RCGCardURISetter1Contract.setURI1(mapIdToWord5[_requestId]));
		URIArray.push(RCGCardURISetter1Contract.setURI1(mapIdToWord6[_requestId]));
		URIArray.push(RCGCardURISetter1Contract.setURI1(mapIdToWord7[_requestId]));
		
		RCGCharacterCardMinterContract.safeMint(mapIdToAddress[_requestId], URIArray);
    }
	//Edit URISetter Address
	function changeRCGCardURISetter1ContractAddress(address _newAddress) public onlyOwner {
        RCGCardURISetter1ContractAddress = _newAddress;
    }
	//Transfer Ownership of Minter Contract if this contract needs to be redeployed
    function transferCCMinterOwnership(address _newOwner) public onlyOwner {
        RCGCharacterCardMinterContract.transferOwnership(_newOwner);
    }
    //Change Character Card Minter Address if New Contract is Deployed
    function changecharacterCardMinterAddress(address _characterCardMinterAddress) public onlyOwner {
        RCGCharacterCardMinterAddress = _characterCardMinterAddress;
    }
    //Withdraw Link
    function withdrawLink() public onlyOwner{
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(address(owner()), link.balanceOf(address(this))), 'Unable to transfer');
    }
    //Withdraw ETH
    function withdrawETH(uint256 amount) public onlyOwner{
        address payable to = payable(address(owner()));
        to.transfer(amount);
    }
}