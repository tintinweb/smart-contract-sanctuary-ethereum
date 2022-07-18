//SPDX-License-Identifier: MIT
/// @title CrowdFund
/// @author etorelan
/// @notice Smart contract enabling to pool money for a specified reciever address during a specific time and have that money sent to the reciever thanks to chainlink keepers running every 24 hours

pragma solidity ^0.8.7;

import "KeeperCompatible.sol";
import "Ownable.sol";
import "ILinkToken.sol";



contract CrowdFund is KeeperCompatibleInterface, Ownable {
    
    ILinkToken iLinkToken;
    uint256 campaignId;
    uint immutable interval = 24 hours;
    uint lastTimeStamp;
    uint linkFee;

    mapping(uint256 => Campaign) campaigns;
    mapping(address => mapping(uint => uint256)) amountFunded;


    constructor(address _linkToken, uint _linkFee){
        lastTimeStamp = block.timestamp;
        campaignId = 1;
        linkFee = _linkFee;
        iLinkToken = ILinkToken(_linkToken);
    }

    modifier isOngoing(uint _campaignId){
        require((block.timestamp > campaigns[_campaignId]._startTime) && (block.timestamp < campaigns[_campaignId]._endTime), "Campaign is not ongoing");
        require(campaigns[_campaignId]._proposed == true, "Campaign is not ongoing");
        _;
    }

    event Propose(
        address _initiator,
        address _receiver,
        uint _campaignId,
        uint32 _startTime,
        uint32 _endTime
    );

    event Fund(address _funder, uint256 _campaignId, uint256 _amount);

    event Withdraw(address _withdrawer, uint256 _campaignId, uint256 _amount);

    event Cancel(uint256 _campaignId);

    event Fulfill(address _receiver, uint256 _campaignId, uint256 _amount);

    event Refund(address _refunder, uint _campaignId, uint _amount);

    struct Campaign {
        address _initiator;
        address _receiver;
        uint32 _startTime;
        uint32 _endTime;
        uint256 _amountFunded;
        uint256 _goal;
        bool _proposed;
    }




    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }


    function performUpkeep(bytes calldata) external override {
        if ((block.timestamp - lastTimeStamp) > interval ) {
            for (uint i = 1; i < campaignId; i++){
                if (campaigns[i]._startTime > 0 && campaigns[i]._endTime <= block.timestamp){
                    fulfill(i);
                }
            }
            lastTimeStamp = block.timestamp;
        }
    }


    function propose(address _receiver, uint32 _startTime, uint32 _endTime, uint256 _goal) external {
        require(iLinkToken.transferFrom(msg.sender, address(this), linkFee), "Link fee was not transferred");
        require(_startTime < _endTime,"_startTime cannot be higher than _endTime.");
        require(_endTime - _startTime <= 30 days, "Campaign duration cannot be longer than 30 days");
        //require( _endTime - _startTime >= 12 hours, "Campaign cannot end sooner than after 12 hours");
        require(_startTime >= block.timestamp, "Campaign cannot start sooner than block.timestamp");
        require(_goal >= 0.01 ether, "Goal is not high enough");

        campaigns[campaignId] = Campaign({_initiator: msg.sender, _receiver:_receiver, _startTime:_startTime, _endTime:_endTime, _amountFunded:0, _goal:_goal, _proposed:true});

        emit Propose(msg.sender, _receiver, campaignId, _startTime, _endTime);

        campaignId += 1;
    }


    function fund(uint32 _campaignId) external payable isOngoing(_campaignId){
        require(_campaignId < campaignId, "Specified ID doesn't exist");
        Campaign storage campaign = campaigns[_campaignId];
        campaign._amountFunded += msg.value;
        amountFunded[msg.sender][_campaignId] += msg.value;

        emit Fund(msg.sender, _campaignId, msg.value);
    }


    function withdraw(uint32 _campaignId, uint _amount) external isOngoing(_campaignId){
        Campaign storage campaign = campaigns[_campaignId];
        require(_amount <= amountFunded[msg.sender][_campaignId], "Specified amount is higher than available amount");

        campaign._amountFunded -= _amount;
        amountFunded[msg.sender][_campaignId] -= _amount;
        payable(msg.sender).transfer(_amount);
        
        emit Withdraw(msg.sender, _campaignId, _amount);
    }


    function cancel(uint _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign._initiator, "msg.sender is not the initiator");
        require(block.timestamp < campaign._startTime, "Campaign can only be cancelled before the start");

        delete campaigns[_campaignId];

        emit Cancel(_campaignId);
    }


    function fulfill(uint _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp > campaign._endTime, "Campaign is not ended");


        uint amountToSend = campaign._amountFunded;
        campaign._amountFunded = 0;
        payable(campaign._receiver).transfer(amountToSend);
        
        delete campaigns[_campaignId];

        emit Fulfill(msg.sender, _campaignId, amountToSend);
    }


    function refund(uint _campaignId) external{
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp > campaign._endTime, "Campaign is not ended");
        require(campaigns[_campaignId]._proposed == true, "Campaign has been fulfilled");
        require(amountFunded[msg.sender][_campaignId] > 0, "Refund unavailable due to no amount funded");
        require(campaign._amountFunded < campaign._goal, "Goal has been achieved, refund is unavailable");

        uint amountToSend = amountFunded[msg.sender][_campaignId];
        amountFunded[msg.sender][_campaignId] = 0;
        campaign._amountFunded -= amountToSend;
        payable(msg.sender).transfer(amountToSend);

        emit Refund(msg.sender, _campaignId, amountToSend);
    }


    function approveKeepers(address _keeperRegistry) public onlyOwner{
        iLinkToken.approve(address(_keeperRegistry), iLinkToken.balanceOf(address(this)));
    }


    function getCampaignID() public view returns(uint){
        return campaignId;
    }


    function getCampaign(uint _campaignId) public view returns(Campaign memory){
        require(_campaignId < campaignId, "Specified ID doesn't exist");
        return campaigns[_campaignId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "KeeperBase.sol";
import "KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

interface ILinkToken {
    function allowance(address owner, address spender)external returns (bool success);
    function approve(address spender, uint256 value) external returns (bool success);
    function balanceOf(address owner) external returns (uint256 balance);
    function decimals() external returns (uint8 decimalPlaces);
    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
    function increaseApproval(address spender, uint256 subtractedValue) external;
    function decreaseAllowance(address spender, uint256 addedValue) external returns (bool success);
    function increaseAllowance(address spender, uint256 subtractedValue) external;
    function totalSupply()  external returns (uint256 totalTokensIssued);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
}