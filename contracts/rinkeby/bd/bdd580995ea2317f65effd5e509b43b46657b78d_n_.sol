/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// File: minimum/minimum.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.7;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "./Strings.sol";
//import "./ERC721.sol";

contract n_{
    address private owner;
    address private owner2;
    address private owner3;

    address private wallet;
    address private account0;
    address private account1;
    string baseURI = "";

    mapping(string => string)private tokenURIs;
    //見えないように
    //string baseURI = "";

    uint public price = 1 wei;

    mapping(string => bool) public minted;
    mapping(address => uint)public haveTokens;
    //ID->mintable counts
    struct allowlistElement{
        uint remaining;
        uint price;
    }

    mapping(address => allowlistElement)public allowlist;
    
    uint256 mintedCount = 0;
    uint256 min = 0;
    uint256 max = 100;
    uint256 seasonMint = 0;

    bool mintStarted = true;
    bool allowlistMintStarted = true;
    string private _name;

    // Token symbol
    string private _symbol;

    
    // Mapping from token ID to owner address
    mapping(string => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;


    mapping(address => bool)allowStoneList;

    //許可リスト
    mapping(address=>bool)private permission;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyOwner(){
        require( msg.sender == owner  || msg.sender == owner2 || msg.sender == owner3 );
        _;
    } 
    
//ここが名前
    constructor(){
        _name = "n";
        _symbol = "n" ;
        //owner address
        //tonoshake
        owner2 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
        //awai san 
        owner = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
        //fale wallet
        //owner3 = address(0x779B9947266ab8515CEd43b2e509122f00c59309);

        //送金先 fale account
        wallet = address(0x779B9947266ab8515CEd43b2e509122f00c59309);
        //awai san wallet
        account0 = address(0x9B2f5909EC0F559dE12948E4cb963838C7bEeFf2);
        //tonoshake_test mainno
        account1 = address(0x5601613b1D2871ed28E3Af31AC9E41DC4A4e8016);
    }

    function getisMintStarted()public view returns(bool){
        return mintStarted;
    }

    function publicSaleMint(string memory _tokenName) external payable callerIsUser{
        require(mintStarted);
        require(msg.value == getPrice());
        require(minted[_tokenName] == false);
        _safeMint( msg.sender , _tokenName);
        minted[_tokenName] = true;
        

        mintedCount++;
        seasonMint++;
    }

    function devMint(string memory _tokenName) external callerIsUser onlyOwner{
        require(minted[_tokenName] == false);
        //_safeMint( msg.sender , nftid);
        _safeMint( msg.sender , _tokenName);
        minted[_tokenName] = true;
        mintedCount++;
    }

    function getIsMinted(string memory _tokenName) public view returns(bool){
        return minted[_tokenName];
    }

    function getHaveTokens(address _address)public view returns(uint){
        return haveTokens[_address];
    }

    function getMintedNFT()public view returns(uint256){
        return mintedCount;
    }

    function getAllowStone(address _stoneAddress)public view returns(bool){
        return allowStoneList[_stoneAddress];
    }

    function setTokenURI( string memory targetnftid ,string memory _uri ) public onlyOwner{
        tokenURIs[targetnftid] = _uri;
    }

    function _setTokenURI( string memory _tokenName ,string memory _uri ) private {
        require(minted[_tokenName]);
        tokenURIs[_tokenName] = _uri;
    }

    function setTokenIDRange_max_min(uint _max,uint _min)public onlyOwner{
        max = _max;
        min = _min;
    }

    function getTokenID_Range()public view returns(uint256 , uint256){
        return (max,min);
    }

    function getPrice() public view returns(uint){
        return price;
    }

    function setPrice(uint _price) public onlyOwner{
        price = _price;
    }

    function getBaseURI()public view returns(string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI)public onlyOwner{
        baseURI = _baseURI;
    }

    function resetSeasonMint()public onlyOwner{
        seasonMint = 0;
    }

    function getSeasonMint()public view returns(uint){
        return seasonMint;
    }

    function addAllowlist(address _address , uint256 _mintableCount,uint _price)public onlyOwner{
        allowlist[_address] = allowlistElement(_mintableCount,_price);
    }

    function getMintableAllowListedCount(address _address)public view returns(uint,uint){
        return (allowlist[_address].remaining,allowlist[_address].price );
    }

    function removeAllowlist(address _address)public onlyOwner{
        allowlist[_address].remaining = 0;
        allowlist[_address].price = price;
    }
    

    function withDraw() public onlyOwner{
        require(permission[account0] == true);
        require(permission[account1] == true);
        uint balance = address(this).balance;
        payable(wallet).transfer(balance);
        permission[account0] = false;
        permission[account1] = false;
    }

    function mintManage(bool _mintStarted)public onlyOwner{
        mintStarted = _mintStarted;
    }

    function allowlistMintManage(bool _allowlistMintStarted)public onlyOwner{
        allowlistMintStarted = _allowlistMintStarted;
    }

    function manageStoneList(address _address,bool _state)public onlyOwner{
        allowStoneList[_address] = _state;
    }

    // function chengeForm(address _sender,uint _id,string memory _uri) external{
    //     require(allowStoneList[msg.sender],"not allowed address");
    //     require(ownerOf(_id) == _sender);
    //     tokenURIs[_id] = _uri;
    // }


    function _safeMint(address to, string memory name)public {
        _balances[to] += 1;
        _owners[name] = to;
    }
}