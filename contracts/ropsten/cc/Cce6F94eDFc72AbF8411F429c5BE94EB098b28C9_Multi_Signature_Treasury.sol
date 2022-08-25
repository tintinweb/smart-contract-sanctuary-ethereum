/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.7;

contract Multi_Signature_Treasury{
    //Addresses
    address public SignerOne;
    address public SignerTwo;
    address public SignerThree;

    event FundsRecieved(uint256 Amount, address From);
    event ProposalCreated(uint256 Amount, address payable Reciever, string Memo);
    event ProposalExecuted(uint256 Amount, address payable Reciever, string Memo);


    constructor(address _1, address _2, address _3){
        require(_1 != _2 && _1 != _3 && _2 != _3);
        SignerOne = _1;
        SignerTwo = _2;
        SignerThree = _3;
        Signer[_1] = true;
        Signer[_2] = true;
        Signer[_3] = true;
    }
    mapping(address => bool) Signer;
    mapping(uint256 => mapping(address => bool)) ProposalSigned;
    Proposal[] public Proposals;

    //Proposals

    struct Proposal{
        uint256 Amount;
        address payable Reciever;
        string Memo;
        uint256 Votes;
        //2 Votes Needed
    }

    function CreateProposal(uint256 Amount, address payable Reciever, string memory Memo) public returns(uint256 ID){
        require(Signer[msg.sender] == true, "Not Signer");

        Proposal memory NewProposal = Proposal(Amount, Reciever, Memo, 0);

        Proposals.push(NewProposal);
        
        uint256 ProposalID = (Proposals.length - 1);
        emit ProposalCreated(Amount, Reciever, Memo);
        return(ProposalID);
    }

    function SignProposal(uint256 ID) public returns(bool Executed){
        require(Signer[msg.sender] == true, "Not Signer");
        require(ProposalSigned[ID][msg.sender] == false, "Already Signed");

        ProposalSigned[ID][msg.sender] = true;
        Proposals[ID].Votes++;

        if(Proposals[ID].Votes == 2){
            ExecuteProposal(ID);
            return(Executed);
        }
        return(false);
    }

    //Proposal Internals and executing


    function ExecuteProposal(uint256 ProposalID) internal{
        uint256 Amount = Proposals[ProposalID].Amount;
        address payable Reciever = Proposals[ProposalID].Reciever;
        require(Amount <= address(this).balance);

        Reciever.transfer(Amount);

        emit ProposalExecuted(Amount, Reciever, Proposals[ProposalID].Memo);
    }

    //Fallback Function for when depositing ETC
    receive() external payable  {
        emit FundsRecieved(msg.value, msg.sender);
    }

}