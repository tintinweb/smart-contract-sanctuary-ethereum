//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISocialScore.sol";
import "./SocialStructs.sol";
import "./SocialScoreStorage.sol";


contract SocialScore is ISocialScore,SocialScoreStorage{
    using AddressArrayLibrary for AddressArrayLibrary.AddressArray;


    constructor(){
        initializeEmotionList();
        initializeUser(msg.sender);
    }
    function auditUser(address user,Emotion emotion,uint score,string memory metadata) override isNotSelfAuditing(user) userMustBeInitialized(user) isValidEmotion(emotion) isAppropriateScore(score) public {
        EmotionData storage userEmotionData = userEmotionDatas[user][emotion];
        uint numberOfAudits = userEmotionData.numberOfAudits;
        numberOfAudits++;
        userEmotionData.numberOfAudits=numberOfAudits;
        userEmotionData.score+=score;
        userEmotionData.auditsMetadata.push(metadata);
        userEmotionData.auditors.push(msg.sender);
        emit User_Audited(msg.sender,user,emotion,numberOfAudits,score,metadata);
    }
    function getOverallScore(address user) override userMustBeInitialized(user) public view returns(uint256){
        uint256 totalScore = 0;
        for(uint8 i=0;i<emotionList.length;i++)
        {
            EmotionData memory data = userEmotionDatas[user][emotionList[i]];
            uint256 emotionMaxScore = data.numberOfAudits*5;
            uint256 emotionCurrentScore = data.score; 
            uint256 partialScore = (emotionMaxScore*emotionCurrentScore)/5;
            totalScore+=partialScore;
        }
        return totalScore;
    }
    function initializeUser(address user) override isNewUser(user) public{
        users.push(user);
        emit User_Initialized(user);
    }
    function getUserEmotionAuditorAtIndex(address user,Emotion e,uint auditorIndex)override userMustBeInitialized(user) isValidEmotion(e) public view returns(address){
        return userEmotionDatas[user][e].auditors[auditorIndex];
    }
    function getUserEmotionScore(address user,Emotion emotion) override userMustBeInitialized(user) isValidEmotion(emotion)  public view returns(uint){
        return userEmotionDatas[user][emotion].score;
    }
    function getUserEmotionNumberOfAudits(address user,Emotion emotion) override userMustBeInitialized(user) isValidEmotion(emotion) public view returns(uint){
        return userEmotionDatas[user][emotion].numberOfAudits;
    }
    function getUserAtIndex(uint index)override public view returns(address){
        return users.addressAtIndex(index);
    }
    function getNumberOfUsers()override public view returns(uint){
        return users.count();
    }
    function getUserEmotionAuditMetadata(address user,Emotion e,uint auditIndex) override userMustBeInitialized(user) isValidEmotion(e) public view returns(string memory){
        return userEmotionDatas[user][e].auditsMetadata[auditIndex];
    }
    function getIsInitialized(address _address)override public view returns(bool){
        return users.contains(_address);
    }

    function initializeEmotionList() private {
        emotionList.push(Emotion.Empathy);
        emotionList.push(Emotion.Assistance);
        emotionList.push(Emotion.Inspirational);
        emotionList.push(Emotion.Friendly);
        emotionList.push(Emotion.Thankfull);
        emotionList.push(Emotion.Other);
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SocialEnums.sol";

interface ISocialScore{
    function auditUser(address user,Emotion emotion,uint score,string memory metadata) external;
    function initializeUser(address user) external;
    function getUserEmotionScore(address user,Emotion emotion) external view returns(uint);
    function getUserEmotionNumberOfAudits(address user,Emotion emotion) external view returns(uint);
    function getUserAtIndex(uint index) external view returns(address);
    function getNumberOfUsers()external view returns(uint);
    function getUserEmotionAuditMetadata(address user,Emotion e,uint auditIndex)external view returns(string memory);
    function getIsInitialized(address _address) external view returns(bool);
    function getUserEmotionAuditorAtIndex(address user,Emotion e,uint auditorIndex) external view returns(address);
    function getOverallScore(address user) external view returns(uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AddressArrayLibrary.sol";
import "./SocialEnums.sol";
import "./SocialStructs.sol";

contract SocialScoreStorage{
    using AddressArrayLibrary for AddressArrayLibrary.AddressArray;

    AddressArrayLibrary.AddressArray internal users;
    mapping(address=>mapping(Emotion => EmotionData)) internal userEmotionDatas;
    Emotion[] internal emotionList;


    event User_Audited(address auditor,address user,Emotion emotion,uint numberOfUserAudits,uint auditScore,string  metadata);
    event User_Initialized(address user);


    modifier isAppropriateScore(uint score){
        if(score>5) revert Audit_Score_Cannot_Be_Above_5_Stars();
        if(score<0) revert Audit_Score_Cannot_Be_Under_0_Stars();
        _;
    }
    modifier userMustBeInitialized(address user){
        if(!users.contains(user)) revert User_Is_Not_Initialized();
        _;
    }
    modifier isValidEmotion(Emotion e){
        if(uint(e)<0) revert Emotion_Is_Not_Valid();
        if(uint(e)>emotionList.length-1) revert Emotion_Is_Not_Valid();
        _;
    }
    modifier isNewUser(address user){
        if(users.contains(user)) revert User_Is_Already_Initialized();
        _;
    }
    modifier isNotSelfAuditing(address userToAudit){
        if(msg.sender == userToAudit) revert Cannot_Audit_YourSelf();
        _;
    }


    error Cannot_Audit_YourSelf();
    error Audit_Meta_Data_Too_Long();
    error User_Is_Already_Initialized();
    error Emotion_Is_Not_Valid();
    error User_Is_Not_Initialized();
    error Audit_Score_Cannot_Be_Under_0_Stars();
    error Audit_Score_Cannot_Be_Above_5_Stars();
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

    struct EmotionData{
        uint numberOfAudits;
        uint score;
        string[] auditsMetadata;
        address[] auditors;
    }

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


enum Emotion{
    Empathy,Assistance,Inspirational,Friendly,Thankfull,Other
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library AddressArrayLibrary {
    
    struct AddressArray {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }

    function push(AddressArray storage self, address key) internal {
        require(!contains(self, key), "AddressSet: key already exists in the set.");
        self.keyPointers[key] = self.keyList.length;
        self.keyList.push(key);
    }

    function count(AddressArray storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function contains(AddressArray storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function addressAtIndex(AddressArray storage self, uint index) internal view returns(address) {
        return self.keyList[index];
    }
    
}