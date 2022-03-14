/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.12;



// File: Blog.sol

contract Blog {

    uint256 totalPostsNumber;
    // This is a comment!
    struct Posts {
        uint256 id;
        string hash;
        address account;
    }

    constructor () public  {
        adminAccounts.push(msg.sender);
        adminAccountsMap[msg.sender] = true;
        allowedAccounts.push(msg.sender);
        allowedAccountsMap[msg.sender] = true;
    }

    Posts[] public posts;
    mapping(address => Posts) peopleMap;

    address[] public allowedAccounts;
    mapping(address => bool) allowedAccountsMap;

    address[] public adminAccounts;
    mapping(address => bool) adminAccountsMap;

    address[] public requestedAccounts;
    mapping(address => bool) requestedAccountsMap;

    modifier onlyAdmin(){
        require(ifUserIsAdmin(msg.sender), "User is not admin.");
        _;
    }

    //add single post
    function addPost(string memory _hash)
    public
    returns (uint256) {
        uint256 _id = totalPostsNumber+1;
        address _account = msg.sender;
        posts.push(Posts(_id, _hash, _account));
        totalPostsNumber++;
        return _id;
    }

    //total number of posts
    function getTotalPostsNumber()
    public
    view
    returns (uint256)  {
        return totalPostsNumber;
    }

    //change hash of single post
    function updateSinglePostHash(uint256 id,string memory _hash)
    public
    payable {
        posts[id].hash =_hash;
    }

    //delete single post
    function deleteSinglePost(uint _id)
    public
    payable
    {
        //delete posts[_id];
        for(uint i = _id; i < posts.length-1; i++){
            posts[i] = posts[i+1];      
        }
        posts.pop();
    }

    //get id of single post
    function getSinglePostId(uint256 id)
    public
    view
    returns (uint256) {
        return posts[id].id;
    }

    //get hash to IPFS of single post
    function getSinglePostHash(uint256 id)
    public
    view
    returns (string memory) {
        return posts[id].hash;
    }

    //get account who created posts
    function getSinglePostAccount(uint256 id)
    public
    view
    returns (address) {
        return posts[id].account;
    }

    function getSinglePost(uint256 id)
    public
    view
    returns ( uint256, string memory, address) {
        return (posts[id].id, posts[id].hash, posts[id].account) ;
    }

    // return arrays of id and hash of all posts
    function getAllPosts()
    public
    view
    returns (uint256[] memory, string[] memory) {
        uint256 indexes = posts.length;
        uint256[] memory ids = new uint256[](indexes);
        string[] memory hash = new string[](indexes);

        for (uint i = 0; i < indexes; i++) {
            Posts memory post = posts[i];
            ids[i] = post.id;
            hash[i] = post.hash;
        }

        return (ids, hash);
    }


    //add new account
    function addAllowedAccountSingle(address _address)
    onlyAdmin
    public
    payable {
        if(ifUserIsAdmin(msg.sender)&& !ifUserIsAllowed(_address)){
            allowedAccounts.push(_address);
            allowedAccountsMap[_address] = true;
        }
    }

    //add new admin account
    function addAdminAccountSingle(address _address)
    onlyAdmin
    public
    {
        if(ifUserIsAdmin(msg.sender) && !ifUserIsAdmin(_address)){
            adminAccounts.push(_address);
            adminAccountsMap[_address] = true;
        }
    }

    //delete admin
    function deleteAdminAccountSingle(address _address)
    public
    payable
    {
        if(ifUserIsAdmin(msg.sender)){
            if(adminAccounts.length == 1){
                adminAccounts.pop();
                delete adminAccountsMap[_address];
            }
            else {
                for(uint i=0;i < adminAccounts.length; i++){
                    if(adminAccounts[i] == _address){
                            for(uint ii = i; ii < adminAccounts.length-1; ii++){
                                adminAccounts[ii] = adminAccounts[ii+1];      
                            }
                            delete adminAccountsMap[_address];
                        adminAccounts.pop();
                    
                        break;
                    }
                
                }
            }
        }
    }

    //add to  requested account
    function addToQueueRequestedSingle(address _address)
    public
    payable {
        if(!ifRequestedAccounts(_address) && !ifUserIsAllowed(_address)){
            requestedAccounts.push(_address);
            requestedAccountsMap[_address] = true;
        }
    }

    //change user from requested to allowed
    function moveRequestedAccountToAllowedSingle(address _address)
    onlyAdmin
    public
    payable {
        if(ifUserIsAdmin(msg.sender) && ifRequestedAccounts(_address)){
            if(requestedAccounts.length == 1){
                requestedAccounts.pop();
                delete requestedAccountsMap[_address];
                addAllowedAccountSingle(_address);
            }
            else {
                for(uint i=0;i < requestedAccounts.length; i++){
                    if(requestedAccounts[i] == _address){
                        if(requestedAccounts.length > 1){
                            for(uint ii = i; ii < requestedAccounts.length-1; ii++){
                                requestedAccounts[ii] = requestedAccounts[ii+1];      
                            }
                            delete requestedAccountsMap[_address];
                        }
                        requestedAccounts.pop();
                    
                        addAllowedAccountSingle(_address);
                        break;
                    }
                
                }
            }
        }
    }

    //get array of allowed account
    function getAllowedAccountAll()
    public
    view
    returns (address [] memory) {
        return allowedAccounts;
    }

    function getAdminAccountsAll()
    public
    view
    returns (address [] memory) {
        return adminAccounts;
    }

    //get array of requested account
    function getRequestedAccountsAll()
    public
    view
    returns (address [] memory) {
        return requestedAccounts;
    }

    function ifUserIsAllowed(address _address)
    public
    view
    returns (bool) {
        return allowedAccountsMap[_address];
    }

    function ifUserIsAdmin(address _address)
    public
    view
    returns (bool) {
        return adminAccountsMap[_address];
    }

    function ifRequestedAccounts(address _address)
    public
    view
    returns (bool) {
        return requestedAccountsMap[_address];
    }


}