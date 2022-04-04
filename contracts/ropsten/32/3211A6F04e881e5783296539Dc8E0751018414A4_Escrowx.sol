/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// AETHER 
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Descrow.sol

pragma solidity ^0.8.0;


contract Escrowx  is ReentrancyGuard {
  
  string public name = 'Escrowx';
  address payable public owner;
  uint public id = 0 ;
  uint256 rate ;
  uint256 ownerShares;
struct contractSchema   {
  
  uint escrowBalance;
  address payable escrowBenefactor;
  address payable escrowBenefactee;
  bool sign1; 
  bool sign2;
  bool isActive;
  




}

event DepositId(uint256 indexed id );
mapping(uint => contractSchema) public contractData;
mapping(address => bool) public hasSigned;
mapping(address => bool) public isActive;





  

constructor(uint256 _rate , address payable _owner ) {
   
    owner = _owner;
    rate = _rate;

}


function depositTokens(address payable benefactee) external payable  nonReentrant{
  
   require(msg.sender != benefactee, ' benefactor and benefactee cannot be the same!');
  
   require(msg.value > 0  , "cannot deposit zero tokens ");
   uint256 amount = msg.value * (100-rate) / 100;  // percentage for the escrow 
   ownerShares += msg.value * rate / 100;
   id += 1;
  contractData[id].escrowBalance =  amount;
  contractData[id].escrowBenefactor = payable(msg.sender);
  contractData[id].escrowBenefactee =  benefactee;
  contractData[id].sign1 = false; 
  contractData[id].sign2 = false;
  contractData[id].isActive = true;
  emit DepositId(id);
}



function releaseTokens(uint Cid) public nonReentrant  {

address payable benefactee = contractData[Cid].escrowBenefactee;

require(contractData[Cid].isActive);

require(msg.sender == contractData[Cid].escrowBenefactor  || msg.sender == contractData[Cid].escrowBenefactee  );

require(contractData[Cid].sign1 && contractData[Cid].sign2);


  uint amount = contractData[Cid].escrowBalance;
 
  
  benefactee.transfer(amount);

  contractData[Cid].isActive = false;



 
 
}

function setRate(uint256 _rate ) external nonReentrant {

  rate= _rate;
}

function mediate(uint isFinished,  uint Conid) public  nonReentrant {
   

  require(msg.sender == owner , "err1");
  // check if contract is still active or finished 
  require(contractData[Conid].isActive);
  address payable benefactee = contractData[Conid].escrowBenefactee;
  address payable benefactor = contractData[Conid].escrowBenefactor;

  uint amount = contractData[Conid].escrowBalance;
 if(isFinished == 1) {
// bagem and tagem finished contract  clean data make sure this contract isnt called again
 benefactee.transfer(amount);

 
  contractData[Conid].isActive = false;

 }
  


 else if(isFinished != 1) {
 
 
 
  benefactor.transfer(amount);

   // bagem and tagem finished contract  clean data make sure this contract isnt called again
   
  

  contractData[Conid].isActive = false;
  
 }
  
  

 
  
}

function sign(uint Conid) public  nonReentrant {
 require(contractData[Conid].isActive, "Contract closed ");
address payable signer = payable(msg.sender);

require( signer == contractData[Conid].escrowBenefactor || signer == contractData[Conid].escrowBenefactee    );

if (signer == contractData[Conid].escrowBenefactor) {
require(!contractData[Conid].sign1, "already signed ");
contractData[Conid].sign1 = true;

}
else {
 require(!contractData[Conid].sign2, "already signed ");
contractData[Conid].sign2 = true;
}



  
  

}

function withdraw() external nonReentrant {
require(msg.sender == owner, "Unauthorized");
require(ownerShares > 0 , "No shares available ");
owner.transfer(ownerShares);
ownerShares = 0;
}

function viewtotal() public view returns (uint256) {
  
  return  address(this).balance;
  

}


}