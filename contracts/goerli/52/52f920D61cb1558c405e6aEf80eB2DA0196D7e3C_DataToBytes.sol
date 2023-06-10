// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract DataToBytes {
    
    function changeCompanyName(string memory _newName) public pure returns(bytes memory){
        return abi.encodeWithSignature("changeCompanyName(string)", _newName);
    }

    function changeShortDescription(string memory _newShortDescription) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeShortDescription(string)", _newShortDescription);
    }

    function changeFullDescriprion(string memory _newfullDescription) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeFullDescriprion(string)", _newfullDescription);
    }

    function changeWebsite(string memory _newWebsite) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeWebsite(string)", _newWebsite);
    }

    function changeVideo(string memory _newVideo) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeVideo(string)", _newVideo);
    }

    function changeCountry(string memory _newCountry) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeCountry(string)", _newCountry);
    }

    function changeOwners(string[] memory _owners) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeOwners(string[])", _owners);
    }

    function changeProjectOwner(address _owner) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeProjectOwner(address)", _owner);
    }

    function changeToken(address _token) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeToken(address)", _token);
    }

    function changeCategory(uint _category) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeCategory(uint256)", _category);
    }

    function changeSoftCap(uint _soft) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeSoftCap(uint256)", _soft);
    }

    function changeHardCap(uint _hard) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeHardCap(uint256)", _hard);
    }

    function changeStart(uint _newStart) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeStart(uint256)", _newStart);
    }

    function changeEnd(uint _newEnd) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeEnd(uint256)", _newEnd);
    }

    function changeHighlights(string[] memory _newHighlights) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeHighlights(string[])", _newHighlights);
    }

    function changeReward(uint _newReward) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeReward(uint256)", _newReward);
    }

    function changeSocialMediaName(string[] memory _name) public pure returns(bytes memory){
        return abi.encodeWithSignature("changeSocialMediaName(string[])", _name);
    }

    function changeSocialMediaLogin(string[] memory _login) public  pure returns(bytes memory){
        return abi.encodeWithSignature("changeSocialMediaLogin(string[])", _login);
    }

    function changeSocialMediaPersonName(string[] memory _name) public pure returns(bytes memory){
        return abi.encodeWithSignature("changeSocialMediaPersonName(string[])", _name);
    }

    function changeSocialMediaPersonLogin(string[] memory _login) public  pure returns(bytes memory){
        return abi.encodeWithSignature("changeSocialMediaPersonLogin(string[])", _login);
    }

    function changeRoadmapDescription(string memory _description, uint _stageToChange) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeRoadMapDescription(string,uint256)", _description, _stageToChange);
    }

    function approveProject() public pure returns(bytes memory) {
        return abi.encodeWithSignature("approveProject()");
    }

    function changeVerification(bool _verified) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeVerification(bool)", _verified);
    }

    function changeFee(uint _newFee) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeFee(uint256)", _newFee);
    }

    function setApplicationFee(uint _newFee) public pure returns(bytes memory) {
        return abi.encodeWithSignature("setApplicationFee(uint256)", _newFee);
    }

    function changeRoadmapFunds(uint _newFunds, uint _stageToChange) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeRoadmapFunds(uint256,uint256)", _newFunds, _stageToChange);
    }

    function allowToClaim(bool _newPosition) public pure returns(bytes memory) {
        return abi.encodeWithSignature("allowToClaim(bool)", _newPosition);
    }

    function cancelProject() public  pure returns(bytes memory){
        return abi.encodeWithSignature("cancelProject()");
    }

    function refund() public pure returns(bytes memory) {
        return abi.encodeWithSignature("refund()");
    }

    function invest(uint amount) public pure returns(bytes memory)  {
        return abi.encodeWithSignature("invest(uint256)", amount);
    } 

    function getCollectedFunds() public pure returns(bytes memory)  {
        return abi.encodeWithSignature("getCollectedFunds()");
    } 

    function accessCheck(bytes[] memory data) public pure returns(bytes memory) {
        return abi.encodeWithSignature("accessCheck(bytes[])", data);
    }

    function distributeProfit() public pure returns(bytes memory) {
        return abi.encodeWithSignature("distributeProfit()");
    }

    function claim() public pure returns(bytes memory) {
        return abi.encodeWithSignature("claim()");
    }

    function changeMinlock(uint _newLock) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeMinlock(uint256)", _newLock);
    }

    function changeSocialMediaPersonType(string[] memory _type) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeSocialMediaPersonType(string[])", _type);
    }

    function changePersonAvatarLink(string[] memory _link) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changePersonAvatarLink(string[])", _link);
    }

    function changeHeaderLink(string memory _link) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeHeaderLink(string)", _link);
    }

    function changePreviewLink(string memory _link) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changePreviewLink(string)", _link);
    }

    function changeWhitepaperLink(string memory _link) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeWhitepaperLink(string)", _link);
    }

    function changeRoadmapLink(string memory _link) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeRoadmapLink(string)", _link);
    }

    function changeBusinessPlanLink(string memory _link) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeBusinessPlanLink(string)", _link);
    }

    function changeAdditionalDocsLink(string memory _link) public pure returns(bytes memory) {
        return abi.encodeWithSignature("changeAdditionalDocsLink(string)", _link);
    }

    function nextStage() public pure returns(bytes memory) {
        return abi.encodeWithSignature("nextStage()");
    }
}