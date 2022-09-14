// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
        string category;
        address seller;
        uint256 price;

    }

    /*
    *@notice Id counter 
    */
    uint256 public privateCount = 0;
    uint256 public publicCount = 0;


    address private owner;

    /*
    *@notice maps user to their library
    */
    mapping(address=>mapping(uint256=>content)) userLib;
    mapping(address=>content[]) privlib;
    mapping(uint256 => content) public getContentById;

    /**
    @notice Events to log public library
    */
    event PublicUpload(string _name, string _Link, string _description, string _category, uint256 price);
    event Share(address _sharer, string _filename, address _to);
    event bought(address _seller, address _buyer, string _name, uint256 _price);


    error incorrectPrice(uint256 price, uint256 paid);
    error not_owner();
    error incorrectId();

    

    /*
    *@notice array of public library items
    */
    content[] public publicLib;

    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    constructor(address _owner)
    {
        owner= _owner;
    }

    /*
    *@notice uploads privately to users library
    *@param _name file name
    *@param _Link IPFS Link
    *@param _description file description
    *@param category file category
    */
    function PrivateUpload(string calldata _name, string calldata _link, string calldata _description, string calldata _category) external
    {
        privateCount++;
        uint256 _privateCount = privateCount;
        userLib[msg.sender][privateCount]=content(_privateCount, _name, _link, _description, _category, msg.sender, 0);
        privlib[msg.sender].push(content(_privateCount, _name, _link, _description, _category, msg.sender, 0));
    }

    /**
    @notice Uploads publicly into array publicLib
    @param _name file name
    @param _Link IPFS Link
    @param _description file description
    @param _category file category
    */
    function publicUpload(string calldata _name, string calldata _Link, string calldata _description, string calldata _category) external returns(string memory)
    {
        publicCount++;
        uint256 pubCount = publicCount;
        content memory Content = content(pubCount,_name, _Link, _description, _category, msg.sender,0);
        publicLib.push(Content);
        emit PublicUpload(_name, _Link, _description, _category, 0);
         return ("Added to Public Library");
    }


    /**
    @notice shares item in library
    @param _to recieve addresses
    @param _ID of file
    */
    function share(address[] calldata _to, uint256 _ID) external returns(string memory)
    {
        if(userLib[msg.sender][_ID].seller != address(0))
        {
         content memory c = userLib[msg.sender][_ID];
        uint256 length= _to.length;
        for(uint256 i=0; i< length; ) {
        require(_to[i] != address(0),"you cant share to zero address");
        
        userLib[_to[i]][_ID] = content(c.ID, c.name, c.Link, c.description, c.category, c.seller,c.price);
        privlib[_to[i]].push(content(c.ID,c.name, c.Link,c.description, c.category, c.seller,c.price));
        emit Share(msg.sender, c.name, _to[i]);
        unchecked {i++; }
        }
        return "shared";
        }else
        {
            revert incorrectId();
        }
    }


    /*
    *@notice view Library items
    */
    function viewPrivateLib() public view returns(content[] memory )
    {
        return privlib[msg.sender];
    }

    /*
    *@notice view public Library items
    */
    function viewPublicLib()public view returns(content[] memory)
    {
        return publicLib;
    }

    /*
    *@notice make private item public for sale
    @param _ID id of item to make public
    @param _price price of item
    */
    function publicSale(uint256 _ID, uint256 _price)external  //note this was our make public funtion
    {
        if(userLib[msg.sender][_ID].seller != address(0))
        {
        content memory c = userLib[msg.sender][_ID];
        publicLib.push(content(c.ID, c.name, c.Link, c.description, c.category, msg.sender, _price));
        emit PublicUpload(c.name, c.Link, c.description, c.category, _price);
        }else
        {
            revert incorrectId();
        }
    }

    /*
    *@notice buy an item from the public marketplace 
    *@param arrayID the position of the item in the public items array
    */
    function buyItem(uint256 _arrayID) external payable
    {
        content memory c= publicLib[_arrayID];
        uint256 feed = c.price;
        if(msg.value!=feed)
        {
            revert incorrectPrice({
                price: feed,
                paid: msg.value
            });
        }
        userLib[msg.sender][c.ID]=content(c.ID,c.name,c.Link,c.description, c.category, c.seller,c.price);
        privlib[msg.sender].push(content(c.ID,c.name,c.Link,c.description, c.category, c.seller,c.price));
        emit bought(c.seller, msg.sender, c.name, c.price);
        payable(c.seller).transfer((feed*95)/100);
    }

    /*
    *@notice front end gets ether value of an item for sale
    *@param arrayID the position of the item in the public items array
    */
    function assetPrice(uint256 _arrayID)external view returns(uint256)
    {
        content memory c= publicLib[_arrayID];
        uint256 feed = (c.price);
        return feed;
    }


     /*
     *@notice changes the owners address
     *@param addr new owner address
     */
    function changeOwner(address _addr)external
    {
        if(msg.sender!= owner)
        {
            revert not_owner();
        }
        owner = _addr;
    }

     /**
     *@notice Withdraws contract Revenue to owner
     */
    function withdraw()external
    {
        if(msg.sender != owner)
        {
            revert not_owner();
        }
        payable(msg.sender).transfer(address(this).balance);
    }
}