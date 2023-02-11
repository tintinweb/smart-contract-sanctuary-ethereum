// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




interface IERC1155CreatorImplementation {
   function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) external ;
   function totalSupply(uint256 tokenId) external view returns(uint256);
   function balanceOf(address account, uint256 id) external view returns (uint256) ;
   function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external  ;
}


contract MultiBurnContract is Ownable {

    IERC1155CreatorImplementation CoreContract ;
    // token id varibaels for burn
    uint256 [] tokenIdsforOEToken = [1];
    uint256 [] tokenIdsforCToken = [2];
    uint256 [] tokenIdsforP1Token = [3];
    uint256 [] tokenIdsforO1Token = [5];
    uint256 [] tokenIdsforO2Token = [4];
    uint256 [] tokenIdsforO3Token = [6];
    uint256 [] tokenIdsforGiveAUtoken = [7,8,9,10];
    uint256 [] tokenIdsforGivePTtoken = [11,7,8,9,10,2];


    //varibale amount for each level of burning
    uint256 [] fixedAmountBurnTwo = [2];
    uint256 [] fixedAmountBurnFive = [5];
    uint256 [] fixedAmountForGiveAUtoken = [2,2,2,2];
    uint256 [] fixedAmountForGivePTtoken = [2,1,1,2,1,20];
    
    //set address of Implementation contract 
    function setAddressBurnContract(address _contract) public onlyOwner {
        CoreContract = IERC1155CreatorImplementation(_contract);
    }

    function _balanceOf(address _address ,  uint256 id) public view returns (uint256) {
        return CoreContract.balanceOf( _address , id);
    }

    function totalSupply(uint256 tokenId) public view returns (uint256){
        return CoreContract.totalSupply(tokenId);
    }

    function _mintFromExtention(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) internal  {
        CoreContract.mintBaseExisting(to, tokenIds, amounts);
    }
    function _burnFromExtention(address account, uint256[] memory tokenIds, uint256[] memory amounts) internal  {
        CoreContract.burn(account, tokenIds, amounts);
    }
 
    //this function burn 2 OEtoken and give you one O1token 
    function reciveO1tokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
        //the balance must be more than 2
       require(_balanceOf(_msgSender(), 1) >= 2 , "the balance of OEtoken is not enough");
        
        // in the params you must give just one number in the array of tokenIds and amounts
       require(tokenIds.length == 1 , "its must just one number");
       require(amounts.length == 1 , "its must just one number");
       
       //token id must be equal to token wants
       require(tokenIds[0] == 5 , "token id must be 5");
       
        //only you can mint one token
       require(amounts[0] == 1 , "amount must be 1");
       require(to[0] == _msgSender() , "address must be caller of function");

       //burn token 
       _burnFromExtention(_msgSender(), tokenIdsforOEToken , fixedAmountBurnTwo );

       //mint new token
       _mintFromExtention(to, tokenIds, amounts);
    }

    //this function burn 2 OEtoken and give you one O2token 
    function reciveO2tokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance must be more than 2
    require(_balanceOf(_msgSender(), 1) >= 2 , "the balance of OEtoken is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 4 , "token id must be 4");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforOEToken , fixedAmountBurnTwo );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }

 
    //this function burn 2 OEtoken and give you one O3token 
    function reciveO3tokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance must be more than 2
    require(_balanceOf(_msgSender(), 1) >= 2 , "the balance of OEtoken is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 6 , "token id must be 6");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforOEToken , fixedAmountBurnTwo );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }

    //this function burn 2 Ctoken and give you one P1token 
    function recivePtokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance must be more than 2
    require(_balanceOf(_msgSender(), 2) >= 2 , "the balance of Ctoken is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 3 , "token id must be 3");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforCToken , fixedAmountBurnTwo );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }

    /**
     * |||||||||||||||||||||||||||||||||||||||||||||||||||
     * ||                                               || 
     * || from this line start level 2 of burning token ||
     * ||                                               ||
     * |||||||||||||||||||||||||||||||||||||||||||||||||||
     */

    //this function burn 5 P1token and give you one AG1token 
    function reciveAG1tokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance must be more than 5
    require(_balanceOf(_msgSender(), 3) >= 5 , "the balance of P1token is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 7 , "token id must be 7");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforP1Token , fixedAmountBurnFive );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }


    //this function burn 5 O1token and give you one AG2token 
    function reciveAG2tokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance must be more than 5
    require(_balanceOf(_msgSender(), 5) >= 5 , "the balance of O1token is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 8 , "token id must be 8");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforO1Token , fixedAmountBurnFive );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }


    //this function burn 5 O2token and give you one AG3token 
    function reciveAG3tokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance must be more than 5
    require(_balanceOf(_msgSender(), 4) >= 5 , "the balance of O2token is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 9 , "token id must be 9");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforO2Token , fixedAmountBurnFive );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }

    //this function burn 5 O3token and give you one AG4token 
    function reciveAG4tokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance must be more than 5
    require(_balanceOf(_msgSender(), 6) >= 5 , "the balance of O3token is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 10 , "token id must be 10");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforO3Token , fixedAmountBurnFive );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }
    

    /**
    * |||||||||||||||||||||||||||||||||||||||||||||||||||
    * ||                                               || 
    * || from this line start level 3 of burning token ||
    * ||                                               ||
    * |||||||||||||||||||||||||||||||||||||||||||||||||||
    */

    //this function burn 2 AG1token , 2 AG2token , 2 AG3token , 2 AG4token and give you one AUtoken 
    function reciveAUtokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance of all toknes must be more then 2
    require(_balanceOf(_msgSender(), 7) >= 2 , "the balance of AG1token is not enough");
    require(_balanceOf(_msgSender(), 8) >= 2 , "the balance of AG2token is not enough");
    require(_balanceOf(_msgSender(), 9) >= 2 , "the balance of AG3token is not enough");
    require(_balanceOf(_msgSender(), 10) >= 2 , "the balance of AG4token is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 11 , "token id must be 11");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be equal to caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforGiveAUtoken , fixedAmountForGiveAUtoken );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }

    //this function burn 2 AUtoken , 2 AG2token , 1 AG1token , 1 AG2token , 2 AG3token , 1 AG4token , 20 Ctoken and give you one PTtoken 
    function recivePTtokenWithBurn(address[] calldata to, uint256[] calldata tokenIds, uint256 [] calldata amounts) public {
    //the balance of token must be more then thing of they want
    require(_balanceOf(_msgSender(), 11) >= 2 , "the balance of AUtoken is not enough");
    require(_balanceOf(_msgSender(), 7) >= 1 , "the balance of AG1token is not enough");
    require(_balanceOf(_msgSender(), 8) >= 1 , "the balance of AG2token is not enough");
    require(_balanceOf(_msgSender(), 9) >= 2 , "the balance of AG3token is not enough");
    require(_balanceOf(_msgSender(), 10) >= 1 , "the balance of AG4token is not enough");
    require(_balanceOf(_msgSender(), 2) >= 20 , "the balance of Ctoken is not enough");
    // in the params you must give just one number in the array of tokenIds and amounts
    require(tokenIds.length == 1 , "its must just one number");
    require(amounts.length == 1 , "its must just one number");

    //token id must be equal to token wants
    require(tokenIds[0] == 12 , "token id must be 12");

    //only you can mint one token
    require(amounts[0] == 1 , "amount must be 1");
    require(to[0] == _msgSender() , "address must be equal to caller of function");

    //burn token 
    _burnFromExtention(_msgSender(), tokenIdsforGivePTtoken , fixedAmountForGivePTtoken );

    //mint new token
    _mintFromExtention(to, tokenIds, amounts);
    }
}