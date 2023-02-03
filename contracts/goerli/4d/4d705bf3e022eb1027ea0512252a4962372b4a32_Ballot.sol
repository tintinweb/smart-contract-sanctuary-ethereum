/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {





    struct NewMemberProposal{

        address  proposedAddress;
        uint expiresUnixTime;
        address[] voters;
        bool refunded;
    }

    NewMemberProposal[] public newmemberpropsals;

    address[] public chairpersons;





    constructor()  {

        chairpersons.push(msg.sender); // we need one chairperson to start!

        
    }

    event newSponsorEvent(address indexed _from, string _value);

    function voteForNewMember (uint _newmemberproposalindex) public {
        require(existschair(msg.sender), "Only another chair can vote"); 
        require(newmemberproposalvalid(_newmemberproposalindex), "Proposal has expired");
        require(alreadyvoted(_newmemberproposalindex, msg.sender) == false, "You have already voted");
        newmemberpropsals[_newmemberproposalindex].voters.push(msg.sender);


    }

    function newmemberproposalvalid (uint _index) public view returns (bool){
        if (newmemberpropsals[_index].expiresUnixTime > block.timestamp) {
            return true;
        }
        return false;

    }
    function existschair(address checkchair) public view returns (bool) {
        for (uint i = 0; i < chairpersons.length; i++) {
            if (chairpersons[i] == checkchair) {
                return true;
            }
        }

        return false;
    }
    
    function currentvotetally(uint _index) public view returns (uint){
        return newmemberpropsals[_index].voters.length;
    }

    function alreadyvoted(uint _index, address voteraddress) public view returns (bool) {
        for (uint i = 0; i < newmemberpropsals[_index].voters.length; i++) {
            if (newmemberpropsals[_index].voters[i] == voteraddress) {
                return true;
            }
        }

        return false;
    }

        function sponsorNewChair() public payable{
        require(msg.value >= 1 ether, "We require a deposit of 1 Eth");
        require(existschair(msg.sender) == false, "You are already a chair member");
        emit newSponsorEvent(msg.sender, "look at me");
        address[] memory emptyarray;
        newmemberpropsals.push(NewMemberProposal({
            proposedAddress: msg.sender,
            expiresUnixTime: block.timestamp + (7 days),
            voters: emptyarray,
            refunded: false
        }));

    }




    function enoughvotes(uint _index) public view returns (bool){
        if (newmemberpropsals[_index].voters.length >= chairpersons.length){
            return true;
        }

        return false;

    }

    function promoteproposal(uint _index) public {

        require(enoughvotes(_index), "Not enough votes");
        require(newmemberpropsals[_index].refunded == false, "Already refunded");
        chairpersons.push(newmemberpropsals[_index].proposedAddress);
        newmemberpropsals[_index].refunded = true;
        address payable refundAddress = payable (newmemberpropsals[_index].proposedAddress);
        refundAddress.transfer(1 ether);

    }

    function cancelproposal(uint _index) public {
        require(newmemberpropsals[_index].refunded == false, "Already refunded");
        require(msg.sender == newmemberpropsals[_index].proposedAddress, "Only proposed address can cancel");
        newmemberpropsals[_index].refunded = true;
        address payable refundAddress = payable (newmemberpropsals[_index].proposedAddress);
        refundAddress.transfer(0.9 ether); // you only get back 90% if you cancel
        uint chairshare = (0.1 ether) / chairpersons.length; //remaining chairs get what is left
        for (uint i = 0; i < chairpersons.length; i++) {
            address payable chairShareAddress = payable (chairpersons[i]);
            chairShareAddress.transfer(chairshare);
        }



    }


     
}