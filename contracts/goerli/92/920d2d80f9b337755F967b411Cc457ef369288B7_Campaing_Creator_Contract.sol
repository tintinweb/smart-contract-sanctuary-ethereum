// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "Ownable.sol";

contract Campaing_Creator_Contract {

  struct Campaing {
    uint id;
    address payable Owner;
    address payable[] Funders;
    uint[] Plans;
    uint TotalAmountFunded;
    uint [] AmountFunded;
    uint CampaingValue;
  }
 
  Campaing[] Campaings;
  address payable[] Funders;
  uint[] AmountFunded;
  uint[] Plans;

  function CreateCampaing(uint _amountToReach) public returns (uint) {
    uint _id = Campaings.length;
    Campaing memory newCampaing = Campaing(_id, payable(msg.sender),Funders,Plans,0,AmountFunded,_amountToReach);
    Campaings.push(newCampaing);
    return Campaings.length;
  }

  function addPlan(uint _Id, uint _PlansValue) public returns(uint, uint) {
    require (
      msg.sender == Campaings[_Id].Owner,
      "You're not the owner of this campaing"
    );
    uint newPlanId = Campaings[_Id].Plans.length;
    Campaings[_Id].Plans.push(_PlansValue);
    return (Campaings[_Id].id, Campaings[_Id].Plans[newPlanId]);
  }

  function getCampaings() public view returns (Campaing[] memory) {
    return Campaings;
  }

  function getCampaing(uint _Id) public view returns (uint, address payable, address payable[] memory, uint[] memory, uint[] memory ,uint, uint) {
    Campaing memory campaing = Campaings[_Id];
    return (
      campaing.id,
      campaing.Owner,
      campaing.Funders,
      campaing.Plans,
      campaing.AmountFunded,
      campaing.TotalAmountFunded,
      campaing.CampaingValue
    );
  }

  function getCampaingsId(uint _Id) public view returns (uint) {
    Campaing memory campaing = Campaings[_Id];
    return campaing.id;
  }

  function getCampaingsOwner(uint _Id) public view returns(address payable) {
    Campaing memory campaing = Campaings[_Id];
    return campaing.Owner;
  }

  function getCampaingsFunders(uint _Id) public view returns (address payable[] memory){
    Campaing memory campaing = Campaings[_Id];
    return campaing.Funders;
  }

  function getCampaingsPlans(uint _Id) public view returns (uint[] memory) {
    Campaing memory campaing = Campaings[_Id];
    return campaing.Plans;
  }

  function getCampaingsPlan(uint _Id, uint _PlanId) public view returns (uint) {
    Campaing memory campaing = Campaings[_Id];
    return campaing.Plans[_PlanId];
  }

  function getCampaingsAmountFundedPerFunder(uint _Id) public view returns (uint[] memory) {
    Campaing memory campaing = Campaings[_Id];
    return campaing.AmountFunded;
  }

  function getCampaingsTotalAmountFunded(uint _Id) public view returns (uint) {
    Campaing memory campaing = Campaings[_Id];
    return campaing.TotalAmountFunded;
  }

  function getCampaingsValue(uint _Id) public view returns (uint) {
    Campaing memory campaing = Campaings[_Id];
    return campaing.CampaingValue;
  }

  function setPlanValue(uint _Id, uint _PlanId, uint _NewPlansValue) public returns(uint, uint) {
    require (
      msg.sender == Campaings[_Id].Owner,
      "You're not the owner of this campaing"
    );
    Campaings[_Id].Plans[_PlanId] = _NewPlansValue;
    return (Campaings[_Id].id, Campaings[_Id].Plans[_PlanId]);
  }

  function FundCampaing (uint _Id, uint _PlanId) public payable returns (uint) {
    require(
      msg.value == Campaings[_Id].Plans[_PlanId],
      "Incorrect Value"
    );
    Campaings[_Id].Funders.push(payable(msg.sender));
    Campaings[_Id].AmountFunded.push(msg.value);
    Campaings[_Id].TotalAmountFunded += msg.value;
    return _Id;
  }

  function DonationForCamaping (uint _Id) public payable {
    Campaings[_Id].TotalAmountFunded += msg.value;
  }

  function payTheCreator(uint _Id) public payable{
    require (
      Campaings[_Id].TotalAmountFunded >= Campaings[_Id].CampaingValue,
      "The campaing hasn't reached the money goal"
    );
    Campaings[_Id].Owner.transfer(Campaings[_Id].TotalAmountFunded);
    Campaings[_Id].TotalAmountFunded = 0;
  }

  function withdraw(uint _Id) public payable returns(uint) {
    require (msg.sender == Campaings[_Id].Owner);
    for (uint i = 0; i<Campaings[_Id].Funders.length; i++) { 
      Campaings[_Id].Funders[i].transfer(Campaings[_Id].AmountFunded[i]);
    }
    Campaings[_Id].Funders = Funders;
    Campaings[_Id].AmountFunded = AmountFunded;
    Campaings[_Id].TotalAmountFunded = 0;
    return Campaings[_Id].TotalAmountFunded;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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