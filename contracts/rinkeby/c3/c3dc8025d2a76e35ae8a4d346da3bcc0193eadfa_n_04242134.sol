pragma solidity =0.8.7;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721.sol";

contract n_04242134 is ERC721{
    address private owner;
    address private owner2;
    address private owner3;

    address private wallet;
    address private account0;
    address private account1;
    string baseURI = "";

    mapping(uint => string)private tokenURIs;
    //見えないように
    //string baseURI = "";

    uint public price = 1 wei;

    mapping(uint => bool) public minted;
    mapping(address => uint)public haveTokens;
    //ID->mintable counts
    struct allowlistElement{
        uint remaining;
        uint price;
    }

    mapping(address => allowlistElement)public allowlist;
    mapping(address => uint256)public public_allowlist;

    uint256 mintedCount = 0;
    uint256 min = 0;
    uint256 max = 100;
    uint256 seasonMint = 0;

    bool mintStarted = true;
    bool allowlistMintStarted = true;
    bool public_allowlistMintStarted = true;

    mapping(address => bool)allowStoneList;

    //許可リスト
    mapping(address => bool)private permission;

    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier owners(){
        require( _msgSender() == owner  || _msgSender() == owner2 || _msgSender() == owner3 );
        _;
    } 
    
//ここが名前
    constructor() ERC721("n_04242134" , "n_04242134" ) {
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

    function publicSaleMint(uint256 _tokenID) external payable callerIsUser{
        require(mintStarted);
        uint256 nftid = _tokenID;
        require(nftid < max);
        require(nftid >= min);
        require(msg.value == getPrice());
        require(minted[nftid] == false);
        _safeMint( _msgSender() , nftid);
        string memory uri = string(abi.encodePacked(baseURI,Strings.toString(nftid),".json") );
        minted[nftid] = true;
        setTokenURI( nftid , uri );
        mintedCount++;
        seasonMint++;
    }

    function devMint(uint256 _tokenID) external callerIsUser owners{
        require(_tokenID < max);
        require(_tokenID >= min);
        require(minted[_tokenID] == false);
        //_safeMint( msg.sender , nftid);
        _safeMint( _msgSender() , _tokenID);
        string memory uri = string(abi.encodePacked(baseURI,Strings.toString(_tokenID),".json") );
        minted[_tokenID] = true;
        _setTokenURI( _tokenID , uri );
        mintedCount++;
    }

    function getIsMinted(uint256 _id) public view returns(bool){
        return minted[_id];
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

    function setTokenURI( uint256 targetnftid ,string memory _uri ) public owners{
        tokenURIs[targetnftid] = _uri;
    }

    function _setTokenURI( uint256 targetnftid ,string memory _uri ) private {
        require(minted[targetnftid]);
        tokenURIs[targetnftid] = _uri;
    }

    function setTokenIDRange_max_min(uint _max,uint _min)public owners{
        max = _max;
        min = _min;
    }

    function getTokenID_Range()public view returns(uint256 , uint256){
        return (max,min);
    }

    function tokenURI(uint256 tokenId)public view override returns (string memory) {
        return tokenURIs[tokenId];
    }

    function getPrice() public view returns(uint){
        return price;
    }

    function setPrice(uint _price) public owners{
        price = _price;
    }

    function getBaseURI()public view returns(string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI)public owners{
        baseURI = _baseURI;
    }

    function resetSeasonMint()public owners{
        seasonMint = 0;
    }

    function getSeasonMint()public view returns(uint){
        return seasonMint;
    }

    function addAllowlist(address _address , uint256 _mintableCount,uint _price)public owners{
        allowlist[_address] = allowlistElement(_mintableCount,_price);
    }

    function addPublicAllowList(address _address , uint256 _mintableCount) public owners{
        public_allowlist[_address] = _mintableCount;
    }

    function getMintableAllowListedCount(address _address)public view returns(uint,uint){
        return (allowlist[_address].remaining,allowlist[_address].price );
    }

    function getMintablePublicAllowListedCount(address _address)public view returns(uint){
        return (public_allowlist[_address] );
    }

    function removeAllowlist(address _address)public owners{
        allowlist[_address].remaining = 0;
        allowlist[_address].price = price;
    }

    function removePublicAllowlist(address _address)public owners{
        public_allowlist[_address] = 0;
    }

    function allowlistMint(uint256 _tokenID)public payable{
        //初期値が0なのでホワイトリストとして使える
        uint256 nftid = _tokenID;
        require(allowlist[msg.sender].remaining > 0);
        require(minted[nftid] == false);
        require(nftid < max);
        require(nftid >= min);
        require(msg.value == allowlist[msg.sender].price);
        _safeMint( _msgSender() , nftid);
        string memory uri = string(abi.encodePacked(baseURI,Strings.toString(nftid),".json") );
        setTokenURI( nftid , uri );
        minted[nftid] = true;
        mintedCount++;
        allowlist[msg.sender].remaining--;
    }

    function publicAllowlistMint(uint256 _tokenID)public payable{
        //初期値が0なのでホワイトリストとして使える
        uint256 nftid = _tokenID;
        require(public_allowlist[msg.sender] > 0);
        require(minted[nftid] == false);
        require(nftid < max);
        require(nftid >= min);
        require(msg.value == getPrice() );
        _safeMint( _msgSender() , nftid);
        string memory uri = string(abi.encodePacked(baseURI,Strings.toString(nftid),".json") );
        setTokenURI( nftid , uri );
        minted[nftid] = true;
        mintedCount++;
        public_allowlist[msg.sender]--;
    }

    function gift(uint256 _tokenID , address _receiver)public payable{
        require(mintStarted);
        require(msg.sender != _receiver);
        uint256 nftid = _tokenID;
        require(nftid < max);
        require(nftid >= min);
        require(msg.value == getPrice());
        require(minted[nftid] == false);
        _safeMint( _receiver , nftid);
        string memory uri = string(abi.encodePacked(baseURI,Strings.toString(nftid),".json") );
        setTokenURI( nftid , uri );
        minted[nftid] = true;
        mintedCount++;
        seasonMint++;
    }

    function permitWithDraw()public owners{
        //require( _msgSender() == owner  || _msgSender() == owner2 || _msgSender() == owner3);

        require(_msgSender() == account0 || _msgSender() == account1);
        permission[msg.sender] = true;
    }

    function withDraw() public owners{
        require(permission[account0] == true);
        require(permission[account1] == true);
        uint balance = address(this).balance;
        payable(wallet).transfer(balance);
        permission[account0] = false;
        permission[account1] = false;
    }

    function mintManage(bool _mintStarted)public owners{
        mintStarted = _mintStarted;
    }

    function public_allowlistMintManage(bool _public_allowlistMintStarted)public owners{
        public_allowlistMintStarted = _public_allowlistMintStarted;
    }

    function allowlistMintManage(bool _allowlistMintStarted)public owners{
        allowlistMintStarted = _allowlistMintStarted;
    }

    function manageStoneList(address _address,bool _state)public owners{
        allowStoneList[_address] = _state;
    }

    function chengeForm(address _sender,uint _id,string memory _uri) external{
        require(allowStoneList[msg.sender],"not allowed address");
        require(ownerOf(_id) == _sender);
        tokenURIs[_id] = _uri;
    }
}