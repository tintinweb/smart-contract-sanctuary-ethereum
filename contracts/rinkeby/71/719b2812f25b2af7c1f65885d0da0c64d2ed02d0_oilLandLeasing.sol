/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

/* This contracts are offered for learning purposes only, to illustrate certain aspects of development regarding web3,
   they are not audited of course and not for use in any production environment.
   They are not aiming to illustrate true randomness or reentrancy control, as a general rule they use transfer() instead of call() to avoid reentrancy,
   which of course only works is the recipient is not intended to be a contract that executes complex logic on transfer.
*/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


contract oilLandLeasing{

   
    event OfferingPlaced (bytes32 indexed offeringId,address indexed offerer,uint _dailyPayoutAmount,uint _initialContractAmount);
    event OfferingClosed(bytes32 indexed offeringId, address indexed buyer);
    event OperatorChanged (address previousOperator, address newOperator);
    event BalanceWithdrawn (address indexed beneficiary, uint amount);

    address operator;
    uint offeringNonce;

    struct landOffering {
        address offerer;
        string  giolocation;
        uint initialContractAmount;
        uint dailyPayoutAmount;
        bool closed;
    }

    mapping (bytes32 => landOffering) offeringRegistry;
    mapping (address => uint) balances;

    constructor (address _operator) {
        operator = _operator;
    }

    function placeOffering (address _offerer, string memory _giolocation,uint _initialContractAmount,uint _dailyPayoutAmount) external {
        require (msg.sender == operator, "Only operator dApp can create offerings");
        bytes32 offeringId = keccak256(abi.encodePacked(offeringNonce, _offerer));
        offeringRegistry[offeringId].offerer = _offerer;
        offeringRegistry[offeringId].giolocation = _giolocation;
        offeringRegistry[offeringId].initialContractAmount = _initialContractAmount;
        offeringRegistry[offeringId].dailyPayoutAmount =_dailyPayoutAmount;
        offeringNonce += 1;
        emit OfferingPlaced(offeringId,_offerer,_initialContractAmount,_dailyPayoutAmount);
    }

    // function closeOffering(bytes32 _offeringId) external payable {
    //     require(msg.value >= offeringRegistry[_offeringId].dailyPayoutAmount, "Not enough funds to buy");
    //     require(offeringRegistry[_offeringId].closed != true, "Offering is closed");
    //     ERC721 hostContract = ERC721(offeringRegistry[_offeringId].hostContract);
    //     offeringRegistry[_offeringId].closed = true;
    //     balances[offeringRegistry[_offeringId].offerer] += msg.value;
    //     //hostContract.safeTransferFrom(offeringRegistry[_offeringId].offerer, msg.sender, offeringRegistry[_offeringId].tokenId);
    //     emit OfferingClosed(_offeringId, msg.sender);
    // }

    function withdrawBalance() external {
        require(balances[msg.sender] > 0,"You don't have any balance to withdraw");
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit BalanceWithdrawn(msg.sender, amount);
    }

    function changeOperator(address _newOperator) external {
        require(msg.sender == operator,"only the operator can change the current operator");
        address previousOperator = operator;
        operator = _newOperator;
        emit OperatorChanged(previousOperator, operator);
    }

    // function viewOffering(bytes32 _offeringId) public view returns (address, uint, uint, bool){
    //     return (offeringRegistry[_offeringId].offerer, offeringRegistry[_offeringId].initialContractAmount, offeringRegistry[_offeringId].dailyPayoutAmount,offeringRegistry[_offeringId].closed);
    // }
    function viewOffering(bytes32 _offeringId) public view returns (uint, uint){
    return (offeringRegistry[_offeringId].initialContractAmount,offeringRegistry[_offeringId].dailyPayoutAmount);
    }

    function viewinitialAmount(bytes32 _offeringId) public view returns (uint){
        return (offeringRegistry[_offeringId].initialContractAmount);
    }
    function dailyPayoutAmount(bytes32 _offeringId) public view returns (uint){
        return (offeringRegistry[_offeringId].dailyPayoutAmount);
    }


    

      function viewBalances(address _address) external view returns (uint) {
        return (balances[_address]);
    }

}