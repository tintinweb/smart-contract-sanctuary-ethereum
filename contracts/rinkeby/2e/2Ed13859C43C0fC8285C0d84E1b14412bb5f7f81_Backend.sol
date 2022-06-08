/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Backend{

    constructor(
        string memory adminPubKey, 
        string memory adminUserSign,
        string memory initCipherKey,
        string memory cipherKeySign,
        string memory initNonce){
        //set admin address, nonce, create admin user, equip with initial key
        admin = msg.sender;
        nonce = initNonce;
        users.push( User(admin, adminPubKey, adminUserSign) );
        addCipherKeyToUser(admin, initCipherKey, cipherKeySign);
    }

    struct CipherKey{
        string text;
        string signature;
    }

    struct Message{
        address sender;
        string payload;
        string signature;
    }

    struct User{
        address identifier;
        string publicKey;
        string signature;
    }

    address private admin;

    string private nonce;

    User[] private users;

    mapping(address => CipherKey[]) private cipherKeys;

    User[] private applicants;

    Message[] private chatMessages;

    //Administrative functions
    
    function getAllUserInfo() external view returns(address[] memory, string[] memory, string[] memory){
        //requirements
        require(msg.sender == admin, "sender!=admin");
        //get information from mappings
        string[] memory pubKeys = new string[](users.length);
        string[] memory signs = new string[](users.length);
        for(uint i=0; i<users.length; i++){
            pubKeys[i] = users[i].publicKey;
            signs[i] = users[i].signature;
        }
        //return arrays
        return (getAllUsers(), pubKeys, signs);
    }
    
    function getAllUsers() public view returns(address[] memory){
        //requirements
        require(isMember(msg.sender, users) >= 0, "not a user");
        //get addresses and return
        address[] memory addresses = new address[](users.length);
        for(uint i=0; i<users.length; i++){
            addresses[i] = users[i].identifier;
        }
        return addresses;
    }
    
    function validateAdmin() external view returns (address, string memory) {
        return (admin, nonce);
    }
    
    function addCipherKeyToUser(address user, string memory keyText, string memory keySignature) private {
        //requirements
        require(msg.sender == admin, "sender!=admin");
        //add key
        CipherKey memory newKey = CipherKey(keyText, keySignature);
        cipherKeys[user].push(newKey);
    }
    
    function newCipherKeyAllocation(string[] memory newKeys, string[] memory newSignatures) private {
        //requirements
        require(msg.sender == admin, "sender!=admin");
        require(newKeys.length == users.length, "keys length mismatch");
        require(newSignatures.length == users.length, "signs length mismatch");
        //add keys to all users
        for(uint i=0; i<users.length; i++){
            addCipherKeyToUser(users[i].identifier, newKeys[i], newSignatures[i]);
        }
    }

    function getCipherKeys() external view returns (string[] memory, string[] memory){
        //requirements
        require(isMember(msg.sender, users) >= 0, "not a user");
        //put information into arrays
        uint arrLen = cipherKeys[msg.sender].length; 
        string[] memory keys = new string[](arrLen);
        string[] memory signs = new string[](arrLen);
        for(uint i=0; i<arrLen; i++){
            CipherKey memory keyObj = cipherKeys[msg.sender][i];
            keys[i] = keyObj.text;
            signs[i] = keyObj.signature;
        }
        //return arrays
        return (keys, signs);
    }

    function isMember(address identifier, User[] memory group) private view returns(int){
        for(uint i=0; i<group.length; i++){
            if(group[i].identifier == identifier){
                return int(i);
            }
        }
        return -1;
    }

    function memberStatus() external view returns(uint){
        if( isMember(msg.sender, users) >= 0 ){
            return 2;
        }else{
            if( isMember(msg.sender, applicants) >= 0 ){
                return 1;
            }else{
                return 0;
            }
        }
    }

    function removeMember(address identifier, User[] storage group) private {
        //requirements
        require(msg.sender == admin, "sender!=admin");
        int idx = isMember(identifier, group);
        require(idx >= 0, "not a member");
        require(group.length > 0,"no members");
        //remove array element
        group[uint(idx)] = group[group.length-1];
        group.pop();
    }
    
    function removeUser(address identifier) private {
        //requirements
        require(identifier != admin,"cannot remove admin");
        //remove user, delete cipherKeys
        removeMember(identifier, users);
        delete cipherKeys[identifier];
    }
    
    function removeApplicant(address identifier) public {
        removeMember(identifier, applicants);
    }

    function viewApplicants() external view returns(address[] memory, string[] memory){
        //requirements
        require(msg.sender == admin, "sender!=admin");
        //return arrays
        address[] memory addresses = new address[](applicants.length);
        string[] memory pubKeys = new string[](applicants.length);
        for(uint i=0; i<applicants.length; i++){
            User memory applicant = applicants[i];
            addresses[i] = applicant.identifier;
            pubKeys[i] = applicant.publicKey;
        }
        return (addresses, pubKeys);
    }

    function clearApplicants() external {
        //requirements
        require(msg.sender == admin, "sender!=admin");
        //delete array contents
        delete applicants;
    }
    
    function requestAccess(string memory publicKey, address aparentAdmin) external {
        //requirements
        require(aparentAdmin == admin, "wrong admin");
        require(isMember(msg.sender, applicants) < 0, "already applied");
        require(isMember(msg.sender, users) < 0, "already user");
        //add to applicants
        applicants.push( User(msg.sender, publicKey, "") );
    }
    
    function approveApplicant(address identifier, string memory userSignature) private {
        //requirements
        require(msg.sender == admin, "sender!=admin");
        int idx = isMember(identifier, applicants);
        require(idx >= 0, "not an applicant");
        require(isMember(identifier, users) < 0, "already user");
        //add to users, remove from applicants
        User memory applicant = applicants[uint(idx)];
        users.push( User(identifier, applicant.publicKey, userSignature) );
        removeApplicant(identifier);
    }

    function secureApproveApplicant(address identifier, string memory userSignature, string[] memory newKeys, string[] memory newSignatures) external {
        approveApplicant(identifier, userSignature);
        newCipherKeyAllocation(newKeys, newSignatures);
    }

    function secureRemoveUser(address identifier, string[] memory newKeys, string[] memory newSignatures) external {
        removeUser(identifier);
        newCipherKeyAllocation(newKeys, newSignatures);
    }

    //Messaging functions
    
    function postMessage(string memory payload, string memory signature) external {
        //requirements 
        require(isMember(msg.sender, users) >= 0, "not a user");
        //add to messages
        chatMessages.push( Message(msg.sender, payload, signature) );
    }

    function fetchChat(uint startIdx) external view returns (address[] memory, string[] memory, string[] memory){
        //requirements
        require(isMember(msg.sender, users) >= 0, "not a user");
        require(startIdx < chatMessages.length || startIdx == 0, "out of bounds");
        //assemble arrays and return
        uint arrLen = chatMessages.length - startIdx;
        address[] memory senders = new address[](arrLen);
        string[] memory payloads = new string[](arrLen);
        string[] memory signatures = new string[](arrLen);
        uint c=0;
        for(uint i=startIdx; i<chatMessages.length; i++){
            Message memory msgObj = chatMessages[i];
            senders[c] = msgObj.sender;
            payloads[c] = msgObj.payload;
            signatures[c] = msgObj.signature;
            c++;
        }
        return (senders, payloads, signatures);
    }

    function chatLength() external view returns (uint){
        //requirements
        require(isMember(msg.sender, users) >= 0, "not a user");
        //return value
        return chatMessages.length;
    }
    
}