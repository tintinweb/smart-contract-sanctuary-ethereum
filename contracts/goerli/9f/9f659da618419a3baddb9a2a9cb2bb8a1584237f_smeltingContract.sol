/**
 *Submitted for verification at Etherscan.io on 2022-11-11
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

// File: smelting_contract.sol


pragma solidity ^0.8.13;



interface oreToken {
    function transferFrom(address, address, uint) external returns (bool); //from to amount
    function allowance(address, address) external returns (uint256); //owner, spender
}
interface ironToken {
    function mint(address, uint256) external;  
    function transferOwnership(address) external; //to
}
interface copperToken {
    function mint(address, uint256) external;  
    function transferOwnership(address) external; //to
}
interface nickelToken {
    function mint(address, uint256) external;  
    function transferOwnership(address) external; //to
}
interface goldToken {
    function mint(address, uint256) external;  
    function transferOwnership(address) external; //to
}
interface platinumToken {
    function mint(address, uint256) external;  
    function transferOwnership(address) external; //to
}
interface wETHContract {
    function deposit() external payable;
    function transfer(address, uint) external;
    function withdraw(uint256) external;
    function approve(address, uint) external;
}
interface SwapContract {
    function setUserAddress(address) external;
    function setOreAmount(uint256) external;
    function swapExactOutputSingle(uint256, uint256) external;
}

contract smeltingContract is VRFV2WrapperConsumerBase, ConfirmedOwner{

    event RequestFulfilled(uint256 requestId, uint256 randomNum, address requestor);

    wETHContract internal constant weth = wETHContract(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    SwapContract internal constant swCon = SwapContract(0x91Fe1517FDf17Ae2C338602d14A3E156013E61d2);

    address internal oreContractAddress = 0x92C92a9E71a6CFcd39B621eb66804Ac28186849F;
    oreToken oreTokenContract = oreToken(oreContractAddress);

    address internal ironContractAddress = 0xd020ee009eBa367b279546C9Ed47Ba49A0Bcb159;
    ironToken ironTokenContract = ironToken(ironContractAddress);

    address internal copperContractAddress = 0x07FC989B730Fd2F6Fe72c9A3294213cea3DA768e;
    copperToken copperTokenContract = copperToken(copperContractAddress);

    address internal nickelContractAddress = 0x2efe634FAD801A68b86Bbbf153935fd6222A1236;
    nickelToken nickelTokenContract = nickelToken(nickelContractAddress);

    address internal goldContractAddress = 0x01F1Fb3293546e257c7fa94fF04B5ab314bdEe50;
    goldToken goldTokenContract = goldToken(goldContractAddress);

    address internal platinumContractAddress = 0xffb97Dc57c5D891560aAE5AF5460Fcf69a217E64;
    platinumToken platinumTokenContract = platinumToken(platinumContractAddress);

    uint256 public linkIn = 1300000000000000000;
    uint256 internal flatRanNum;
    uint256 internal oreCount;
    uint256 internal oreAllowance;
   
    mapping(uint256 => uint256) public mapIdToWords; //Results to ID
    mapping(uint256 => uint256) public mapIdToOreAmount; //Ore Amount to ID
    mapping(uint256 => address) public mapIdToAddress; //Address to ID
    mapping(uint256 => bool) public mapIdToFulfilled; //Completion Status to ID
    
    uint256 public lastRequestID;

    uint32 callbackGasLimit = 800000;
    uint16 requestConfirmations = 3;
    
    // Address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    constructor() ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) payable{}

    function loadSmelter(uint256 _oreAmount) external payable {
        //Check Allowance
        oreAllowance = oreTokenContract.allowance(msg.sender, address(this));
        require (oreAllowance >= _oreAmount, "Not enough ORE approved.");

        weth.deposit{value: msg.value}();
        weth.approve(address(swCon), msg.value);
        swCon.swapExactOutputSingle(linkIn, msg.value);
        smeltOre(_oreAmount);
    }

    function smeltOre(uint256 _oreAmount)private{
        //Get this because we doing some chainlink stuff.
        oreCount = _oreAmount;

        bool successfulTransfer = oreTokenContract.transferFrom(msg.sender, address(this), _oreAmount);
        
        if (successfulTransfer){  
            //Mint Random Token
            requestRandomWords();
        }
    }
    
    function setLinkIn(uint256 _linkIn) public onlyOwner {
        linkIn = _linkIn;
    }
    
    function requestRandomWords() private returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, 1);
    
        //New Ones
        mapIdToAddress[requestId] = msg.sender;
        mapIdToOreAmount[requestId] = oreCount;
        mapIdToFulfilled[requestId] = false;
        lastRequestID = requestId;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(mapIdToFulfilled[_requestId] == false, 'request fulfilled already');
        mapIdToFulfilled[_requestId] = true;
        flatRanNum = (_randomWords[0] % 100) + 1; //Flatten the random number.
        mapIdToWords[_requestId] = flatRanNum; //Store it.
        mintAlloy(mapIdToWords[_requestId], mapIdToOreAmount[_requestId], mapIdToAddress[_requestId]);
        emit RequestFulfilled(_requestId, flatRanNum, mapIdToAddress[_requestId]); //ID, NUM, Requestor
    }

    function mintAlloy(uint256 _ranNum, uint256 _mintAmount, address _msgSender) private{
       if (_ranNum > 94){
           mintPlatinum(_msgSender, _mintAmount);
       }
       else if (_ranNum > 84){
          mintGold(_msgSender, _mintAmount); 
       }
       else if (_ranNum > 64){
          mintNickel(_msgSender, _mintAmount); 
       }
       else if (_ranNum > 38){
          mintCopper(_msgSender, _mintAmount); 
       }
       else{
          mintIron(_msgSender, _mintAmount); 
       }
       withdrawLink();
    }
    
    ////////////////.   ALLOY FUNCTIONS   ./////////////////////

    //IRON
    function mintIron(address _msgSender, uint256 _amount) private{
        ironTokenContract.mint(_msgSender, _amount);
    }
    function transferIronContractOwnership(address _toAddress) public onlyOwner{
        ironTokenContract.transferOwnership(_toAddress);
    }
    function changeIronContractAddress(address _ironContractAddress) public onlyOwner {
        ironContractAddress = _ironContractAddress;
    }
    //COPPER
    function mintCopper(address _msgSender, uint256 _amount) private{
        copperTokenContract.mint(_msgSender, _amount);
    }
    function transferCopperContractOwnership(address _toAddress) public onlyOwner{
        copperTokenContract.transferOwnership(_toAddress);
    }
    function changeCopperContractAddress(address _copperContractAddress) public onlyOwner {
        copperContractAddress = _copperContractAddress;
    }
    //NICKEL
    function mintNickel(address _msgSender, uint256 _amount) private{
        nickelTokenContract.mint(_msgSender, _amount);
    }
    function transferNickelContractOwnership(address _toAddress) public onlyOwner{
        nickelTokenContract.transferOwnership(_toAddress);
    }
    function changeNickelContractAddress(address _nickelContractAddress) public onlyOwner {
        nickelContractAddress = _nickelContractAddress;
    }
    //GOLD
    function mintGold(address _msgSender, uint256 _amount) private{
        goldTokenContract.mint(_msgSender, _amount);
    }
    function transferGoldContractOwnership(address _toAddress) public onlyOwner{
        goldTokenContract.transferOwnership(_toAddress);
    }
    function changeGoldContractAddress(address _goldContractAddress) public onlyOwner {
        goldContractAddress = _goldContractAddress;
    }
    //Platinum
    function mintPlatinum(address _msgSender, uint256 _amount) private{
        platinumTokenContract.mint(_msgSender, _amount);
    }
    function transferPlatinumContractOwnership(address _toAddress) public onlyOwner{
        platinumTokenContract.transferOwnership(_toAddress);
    }
    function changePlatinumContractAddress(address _platinumContractAddress) public onlyOwner {
        platinumContractAddress = _platinumContractAddress;
    }
    
    function withdrawLink() public {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(address(owner()), link.balanceOf(address(this))), 'Unable to transfer');
    }
}