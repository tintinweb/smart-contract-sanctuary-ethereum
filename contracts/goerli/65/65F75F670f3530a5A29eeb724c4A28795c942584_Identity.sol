//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Identity{

    struct About{
        string typeOfScience;
        string role;
        string aboutYou;
    }

    mapping(address => string) public addressToCredentialsTwitter;
    mapping(string => address) public  CredentialsToAddressTwitter;

    mapping(address => string) public addressToCredentialsGithub;
    mapping(string => address) public  CredentialsToAddressGithub;

    mapping(address => string) public addressToCredentialsOrcid;
    mapping(string => address) public  CredentialsToAddressOrcid;

    address[] public registeredAddressesTwitter;
    string[] public registeredCredentialsTwitter;

    address[] public registeredAddressesGithub;
    string[] public registeredCredentialsGithub;

    address[] public registeredAddressesOrcid;
    string[] public registeredCredentialsOrcid;    

    mapping (address => About) addressToAbout;
    address[] public userAddresses;
    About[] public allUserData;

    function setAbout(address _address, string memory _typeOfScience, string memory _role, string memory _aboutYou) public {

      addressToAbout[_address].typeOfScience =  _typeOfScience;
      addressToAbout[_address].role = _role;
      addressToAbout[_address].aboutYou = _aboutYou;

      userAddresses.push(_address); 
      //allUserData.push(addressToAbout[_address]); 
    }

    function getAbout(address _address) public view returns (string memory, string memory, string memory){
        return(addressToAbout[_address].typeOfScience, addressToAbout[_address].role, addressToAbout[_address].aboutYou);
    }

    // function getAllUserData() public view returns (About[] memory){
    //     return allUserData;
    // }

    function existsTwitterAccount(string memory _account) public view returns(bool){
        for (uint i = 0; i < registeredCredentialsTwitter.length; i++){
            if((keccak256(abi.encodePacked(registeredCredentialsTwitter[i])) == keccak256(abi.encodePacked(_account)))){
                return true;
            }
            }
            return false;
    }

    function LinkYourAddressToTwitter(string memory creds) public {
        //checks if the account is already linked
        require( (keccak256(abi.encodePacked(addressToCredentialsTwitter[msg.sender])) != keccak256(abi.encodePacked(creds))), "You are already registered");
        
        //checks if the same username is used before
        require(existsTwitterAccount(creds) == false, "This twitter account is already linked on-chain");

        addressToCredentialsTwitter[msg.sender] = creds;
        registeredCredentialsTwitter.push(creds);
       
    }

    function showLinkedCredentialsTwitter(address) public view returns (string memory){
        return addressToCredentialsTwitter[msg.sender];
    }

     function existsGithubAccount(string memory _account) public view returns(bool){
        for (uint i = 0; i < registeredCredentialsGithub.length; i++){
            if((keccak256(abi.encodePacked(registeredCredentialsGithub[i])) == keccak256(abi.encodePacked(_account)))){
                return true;
            }
            }
            return false;
    }

    function LinkYourAddressToGithub(string memory creds) public {

        require( (keccak256(abi.encodePacked(addressToCredentialsGithub[msg.sender])) != keccak256(abi.encodePacked(creds))), "You are already registered");

        require(existsGithubAccount(creds) == false, "This Github account is already linked on-chain");

        addressToCredentialsGithub[msg.sender] = creds;
        registeredCredentialsGithub.push(creds);
    }



    function showLinkedCredentialsGithub(address) public view returns (string memory){
        return addressToCredentialsGithub[msg.sender];
    }

    function existsOrcidAccount(string memory _account) public view returns(bool){
        for (uint i = 0; i < registeredCredentialsOrcid.length; i++){
            if((keccak256(abi.encodePacked(registeredCredentialsOrcid[i])) == keccak256(abi.encodePacked(_account)))){
                return true;
            }
            }
            return false;
    }

    function LinkYourAddressToOrcid(string memory creds) public {

        require( (keccak256(abi.encodePacked(addressToCredentialsOrcid[msg.sender])) != keccak256(abi.encodePacked(creds))), "You are already registered");

        require(existsOrcidAccount(creds) == false, "This Orcid account is already linked on-chain");

        addressToCredentialsOrcid[msg.sender] = creds;
        registeredCredentialsOrcid.push(creds);
    }

    function showLinkedCredentialsOrcid(address) public view returns (string memory){
        return addressToCredentialsOrcid[msg.sender];
    }

    function showAllLikedTwitter() public view returns(string[] memory){
        return registeredCredentialsTwitter;
    }

    function showAllLikedGithub() public view returns(string[] memory){
        return registeredCredentialsGithub;
    }

    function showAllLikedOrcid() public view returns(string[] memory){
        return registeredCredentialsOrcid;
    }


}