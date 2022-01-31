/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Oracle {
    
  
    struct Offer {
        string title;
        string description;
        uint256 reward;
        uint256 numberOfOracles;
        uint256 oracleLockValue;
        uint256 deadline;
        uint256 id;
    }

    struct answerType{
        address[] senders;
        uint256 answersCount;
        string fileHash;
        string fileUrl;
    }

    struct MoreInfo {
        address owner;
        uint256 answersTypeCount;
        uint256 oraclesCount;
        mapping (uint256 => answerType) answers;
        bool answered;
        string finalAnswer;
    }

    mapping(uint256 => Offer) private offers;
    mapping(uint256 => MoreInfo) private moreinfo;

    uint256 private offersCount;
    uint256 private activeOffersCount;

    event NewOffer(Offer);
    event OfferEnded(Offer);

    function createOffer(
        string calldata title,
        string calldata description,
        uint256 numberOfOracles,
        uint256 oracleLockValue,
        uint256 activeDays
    ) public payable returns (uint256) {
        require(msg.value > 0, "Reward must be greater than 0");

        Offer storage o = offers[++offersCount];
        o.title = title;
        o.description = description;
        o.reward = msg.value;
        o.numberOfOracles = numberOfOracles;
        o.oracleLockValue = oracleLockValue;
        o.deadline = block.timestamp + (activeDays * 24 * 60 * 60);
        o.id = offersCount;

        MoreInfo storage i = moreinfo[offersCount];
        i.owner = msg.sender;
        i.answered = false;
        i.finalAnswer = "Not answered.";

        activeOffersCount++;

        emit NewOffer(o);

        return offersCount;
    }

    function getOffer(uint256 offerNumber) public view returns (Offer memory) {
        return offers[offerNumber];
    }

    function getActiveOffers() public view returns (Offer[] memory) {
        Offer[] memory activeOffers = new Offer[](activeOffersCount);

        uint256 j = 0;

        for (uint256 i = 0; i <= offersCount; i++) {
            if ((block.timestamp < offers[i].deadline) && (moreinfo[i].answered == false)) {
                activeOffers[j] = offers[i];
                j++;
            }
        }

        return activeOffers;
    }
    function submitAnswer(uint256 offerNumber, string memory fileHash, string memory url) public payable{
        require(msg.value == offers[offerNumber].oracleLockValue, "Wrong lock value.");
        require(moreinfo[offerNumber].oraclesCount < offers[offerNumber].numberOfOracles );
        if(moreinfo[offerNumber].answersTypeCount == 0){
            moreinfo[offerNumber].oraclesCount++;
            moreinfo[offerNumber].answersTypeCount++;
            answerType storage answer = moreinfo[offerNumber].answers[moreinfo[offerNumber].answersTypeCount];
            answer.senders.push(msg.sender);
            answer.answersCount=1;
            answer.fileHash=fileHash;
            answer.fileUrl=url;
        }else{
            bool found=false;
            for (uint256 i = 0; i <=  moreinfo[offerNumber].answersTypeCount; i++) {
                string memory oldFileHash=moreinfo[offerNumber].answers[i].fileHash;
                if(keccak256(abi.encodePacked(oldFileHash)) == keccak256(abi.encodePacked(fileHash))){
                    moreinfo[offerNumber].oraclesCount++;
                    answerType storage answer = moreinfo[offerNumber].answers[i];
                    answer.senders.push(msg.sender);
                    answer.answersCount++;
                    found=true;
                }
            }
            if(found == false){
            moreinfo[offerNumber].oraclesCount++;
            moreinfo[offerNumber].answersTypeCount++;
            answerType storage answer = moreinfo[offerNumber].answers[moreinfo[offerNumber].answersTypeCount];
            answer.senders.push(msg.sender);
            answer.answersCount=1;
            answer.fileHash=fileHash;
            answer.fileUrl=url;
            }

        }
        if(offers[offerNumber].numberOfOracles==moreinfo[offerNumber].oraclesCount){
                        calculateResult(offerNumber);
                    }

    }
    function calculateResult(uint256 offerNumber) private{
        if(moreinfo[offerNumber].answered == false){
            if((moreinfo[offerNumber].oraclesCount == offers[offerNumber].numberOfOracles) ){
            if(moreinfo[offerNumber].answersTypeCount == 1){
                uint256 reward =offers[offerNumber].oracleLockValue + (offers[offerNumber].reward / offers[offerNumber].numberOfOracles);
                moreinfo[offerNumber].finalAnswer = moreinfo[offerNumber].answers[1].fileUrl;
                moreinfo[offerNumber].answered == true;
                for(uint256 i =0;i< moreinfo[offerNumber].answers[1].senders.length; i++){
                payable(moreinfo[offerNumber].answers[1].senders[i]).transfer(reward);
                }
            }else{
                moreinfo[offerNumber].answered == true;
                answerType memory winner = moreinfo[offerNumber].answers[1];
                for(uint256 j = 2; j <= moreinfo[offerNumber].answersTypeCount; j++){
                    if(winner.answersCount < moreinfo[offerNumber].answers[j].answersCount){
                        winner = moreinfo[offerNumber].answers[j];
                    }
                }
                if(winner.senders.length>=2){
                moreinfo[offerNumber].finalAnswer = winner.fileUrl;
                uint256 losingOraclesCount = moreinfo[offerNumber].oraclesCount - winner.answersCount;
                uint256 reward= offers[offerNumber].oracleLockValue + (offers[offerNumber].reward / winner.answersCount) + ((offers[offerNumber].oracleLockValue * losingOraclesCount)/winner.answersCount);
                for(uint256 k =1;k <= winner.senders.length; k++){
                    payable(winner.senders[k]).transfer(reward);
                }
                }else{
                    retunrnRewardAndLockValue(offerNumber);
                }

            }
            }
        else if(block.timestamp > offers[offerNumber].deadline){
            retunrnRewardAndLockValue(offerNumber);
            }
          
        }
    }
    function retunrnRewardAndLockValue(uint256 offerNumber) private{
        if(keccak256(abi.encodePacked(moreinfo[offerNumber].finalAnswer))!=keccak256(abi.encodePacked("Offer canceled!"))){
        moreinfo[offerNumber].finalAnswer="Offer canceled!";
        payable(moreinfo[offerNumber].owner).transfer(offers[offerNumber].reward);
        for(uint256 i =1; i<=moreinfo[offerNumber].answersTypeCount;i++){
            for(uint j =1; j<=moreinfo[offerNumber].answers[i].senders.length;j++){
            payable(moreinfo[offerNumber].answers[i].senders[j]).transfer(offers[offerNumber].oracleLockValue);
            }
        }
      }
    }
    function getAnswer(uint256 offerNumber) public  returns (string memory){
        require(moreinfo[offerNumber].owner == msg.sender, "You are not the owner of this offer.");
        if(moreinfo[offerNumber].answered == false){
            calculateResult(offerNumber);
        }
        return moreinfo[offerNumber].finalAnswer;


    }
}