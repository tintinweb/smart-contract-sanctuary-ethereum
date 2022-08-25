/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity ^0.8.7;

contract YVC {
    address verifier;
    string channelName;
    string videoName;
    string linkOfVideo;
    string startVulnerableDuration;
    string endVulnerableDuration;

    struct VerifyContent  {
        uint256 contractID;
        bool isChannelName;
        bool isVideoName;
        bool isLinkOfVideo;
        bool isStartVulnerableDuration;
        bool isEndVulnerableDuration;
        string verifyResult;
    }

    mapping(uint256 => VerifyContent) public verifyContent;

    constructor() {
        verifier = msg.sender;
    }

    function setContent(
        string memory _channelName, 
        string memory _videoName, 
        string memory _linkOfVideo,
        string memory _startVulnerableDuration,
        string memory _endVulnerableDuration
    ) public {
        channelName = _channelName;
        videoName = _videoName;
        linkOfVideo = _linkOfVideo;
        startVulnerableDuration = _startVulnerableDuration;
        endVulnerableDuration = _endVulnerableDuration;
    }

    function getChannelName() public view returns(string memory) {
        return channelName;
    }

    function getVideoName() public view returns(string memory) {
        return videoName;
    }

    function getLinkOfVideo() public view returns(string memory) {
        return linkOfVideo;
    }

    function getStartVulnerableDuration() public view returns(string memory) {
        return startVulnerableDuration;
    }

    function getEndVulnerableDuration() public view returns(string memory) {
        return endVulnerableDuration;
    }

    // Verify content
    function setVerifyContent(uint256 _contractID, 
                            bool _isChannelName,
                            bool _isVideoName,
                            bool _isLinkOfVideo,
                            bool _isStartVulnerableDuration,
                            bool _isEndVulnerableDuration
    ) public {
        verifyContent[_contractID].contractID = _contractID;
        verifyContent[_contractID].isChannelName = _isChannelName;
        verifyContent[_contractID].isVideoName = _isVideoName;
        verifyContent[_contractID].isLinkOfVideo = _isLinkOfVideo;
        verifyContent[_contractID].isStartVulnerableDuration = _isStartVulnerableDuration;
        verifyContent[_contractID].isEndVulnerableDuration = _isEndVulnerableDuration;
        
        if(verifyContent[_contractID].isLinkOfVideo == false) {
            verifyContent[_contractID].verifyResult = "Due to verifier, link is not correct to verify";
            verifyContent[_contractID].isStartVulnerableDuration = false;
            verifyContent[_contractID].isEndVulnerableDuration = false;
        } 
        // isLinkOfVideo == true
        else if (verifyContent[_contractID].isStartVulnerableDuration == false || 
                verifyContent[_contractID].isEndVulnerableDuration == false) {
            verifyContent[_contractID].verifyResult = "Due to verifier, range of duration vulnerable content is not correct";
        } 
        
        else if (verifyContent[_contractID].isLinkOfVideo == true &&
                verifyContent[_contractID].isStartVulnerableDuration == true &&
                verifyContent[_contractID].isEndVulnerableDuration == true) {
            verifyContent[_contractID].verifyResult = "Due to verifier, video contain vulnerable content";
        }
    }

    function getVerifyContent(uint256 _contractID) external view returns(VerifyContent memory) {
        return verifyContent[_contractID];
    }
}