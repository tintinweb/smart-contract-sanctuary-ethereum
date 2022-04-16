//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Library
{
    /*
    *@notice Instance of Library Item
    */
    struct content
    {
        uint256 ID;
        string name;
        string Link;
        string description;
    }

    /*
    *@notice Id counter 
    */
    uint256 public count = 0;
    uint256 public Pcount = 0;

    /*
    *@notice maps user to their library
    */
    mapping (address=>mapping(uint256=>content)) userLib;
    mapping (address=>content[])privlib;

    /**
    @notice Events to log public library
    */
    event PublicUpload(string _name, string _Link, string _description);
    event Share(address sharer, string _filename, address _to);
    

    /*
    *@notice array of public library items
    */
    content[] public publicLib;

    /*
    *@notice uploads privately to users library
     @param _name file name
    @param _Link IPFS Link
    @param _description file description
    */
    function PrivateUpload(string memory _name, string memory _Link, string memory _description) public
    {
        count++;
        uint256 Count = count;
        userLib[msg.sender][count]=content(Count,_name, _Link, _description);
        privlib[msg.sender].push(content(Count,_name, _Link,_description));
    }

    /**
    @notice Uploads publicly into array publicLib
    @param _name file name
    @param _Link IPFS Link
    @param _description file description
    */
    function publicUpload(string memory _name, string memory _Link, string memory _description) public returns(string memory)
    {
        Pcount++;
        uint256 pcount = Pcount;
        content memory Content = content(pcount,_name, _Link, _description);
        publicLib.push(Content);
        emit PublicUpload(_name, _Link, _description);
         return ("Added to Public Library");
    }


    /**
    @notice shares item in library
    @param _to recieve addresses
    @param _ID of file
    */
    function share(address[] memory _to, uint256 _ID) public returns(string memory)
    {
         content memory c = userLib[msg.sender][_ID];
        
        for(uint256 i=0; i<_to.length; i++) {
        require(_to[i] != address(0),"you cant share to zero address");
        
        userLib[_to[i]][_ID] = content(c.ID, c.name, c.Link, c.description);
        privlib[_to[i]].push(content(c.ID,c.name, c.Link,c.description));
        emit Share(msg.sender, c.name, _to[i]);
        }
        return "shared";
    }


    /*
    *@notice view Library items
    */
    function viewPrivateLib() public view returns(content[] memory )
    {
        return privlib[msg.sender];
    }

    /*
    *@notice make private item public
    @param _ID id of item to make public
    */
    function makePublic(uint256 _ID)public
    {
        content memory c = userLib[msg.sender][_ID];
         publicLib.push(c);
          emit PublicUpload(c.name, c.Link, c.description);
    }
}