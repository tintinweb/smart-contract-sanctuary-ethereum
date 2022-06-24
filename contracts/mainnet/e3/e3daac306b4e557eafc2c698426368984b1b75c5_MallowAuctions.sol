// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./LOVE.sol";
import "./Strings.sol";
import "./Firepit.sol";

contract MallowAuctions is Ownable{
    using Strings for uint;
    
    struct Auction{
        uint256 id;
        uint auctionType;   
        string projectName;
        uint256 startTime;
        uint256 dutchPriceRate;
        uint256 dutchTimeRate;
        uint256 startPrice;
        uint256 minPrice;
        string imgSrc;
        string discordLink;
        string twitterLink;
        uint256 maxWhitelists;
        uint256 req;
        bool exists;
    }

    struct AllInfoRequest{
        Auction auction;
        address[] wlArray;
        uint256 price;
        bool isWL;
    }

    enum State{
        OPEN,
        CLOSED,
        UPCOMING,
        REMOVED
    }

    uint256 public totalAuctions = 0;

    address signer = 0xeFB45a786C8A9fE6D53DdE0E3A4DB6aF54C73DA7;

    mapping(address => bool) public isApprovedAddress; 
    mapping(string => bool) public auctionExists;   
    mapping(uint256 => Auction) auctionSettings; 
    mapping(uint256 => address[]) whitelists; 
    
    LOVE public loveContract;   
    Firepit public firepitContract; 

    modifier onlyApprovedAddresses{
        require(isApprovedAddress[msg.sender], "UNAUTHORIZED");
        _;
    }
    
    function enterAuction(uint256 _auctionId, uint256[] calldata _tokenIds, bytes calldata _signature) external {
        require(auctionSettings[_auctionId].exists, "Auction does not exist or removed");
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, _tokenIds, _auctionId))), _signature) == signer, "INVALID SIGNATURE");
        require(getAuctionState(_auctionId) == State.OPEN, "Auction not open");
        require(!isWhitelisted(msg.sender,_auctionId), "Already whiteListed");
        require(_tokenIds.length >= auctionSettings[_auctionId].req, "Insufficient requirements");
        require(firepitContract.isOwnerOfStakedTokens(_tokenIds, msg.sender), "Not owner of staked tokens");
        uint256 auctionPrice = getCurrentPrice(_auctionId);
        require(loveContract.balanceOf(msg.sender) >= auctionPrice * 1 ether, "Not enough LOVE");
        loveContract.burn(msg.sender, auctionPrice * 1 ether);
        whitelists[_auctionId].push(msg.sender);
    }
    
    function createDutch (string memory _projectName, uint256 _startTime, uint _dutchRate, uint256 _timeRate, uint256 _startPrice, 
    uint256 _minPrice, string memory _imgSrcLink, string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists, uint256 _req) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name already defined");
        require(!auctionSettings[totalAuctions].exists,"Auction already exists");
        require(_startTime > 0 ,"Incorret time value");
        require(_startPrice > 0 ,"Incorret start price value");
        require(_minPrice > 0 ,"Incorret min price value");
        require(_maxWhitelists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 1,   
            projectName: _projectName,
            startTime: _startTime,
            dutchPriceRate: _dutchRate,
            dutchTimeRate: _timeRate,
            startPrice: _startPrice,
            minPrice: _minPrice,
            imgSrc: _imgSrcLink,
            discordLink: _discordLink,
            twitterLink: _twitterLink,
            maxWhitelists: _maxWhitelists,
            req: _req,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    
    function createBuyNow (string memory _projectName, uint _startTime, uint256 _startPrice, string memory _imgSrcLink, 
    string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists, uint256 _req) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name already defined");
        require(!auctionSettings[totalAuctions].exists,"Auction already exists");
        require(_startTime > 0 ,"Incorret time value");
        require(_startPrice > 0 ,"Incorret start price value");
        require(_maxWhitelists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 0,   
            projectName: _projectName,
            startTime: _startTime,
            dutchPriceRate: 0,
            dutchTimeRate: 0,
            startPrice: _startPrice,
            minPrice: _startPrice,
            imgSrc: _imgSrcLink,
            discordLink: _discordLink,
            twitterLink: _twitterLink,
            maxWhitelists: _maxWhitelists,
            req: _req,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    
    function updateAuction(uint256 _auctionId, string memory _projectName, uint256 _startTime, uint _dutchRate,uint256 _timeRate, uint256 _startPrice, 
    uint256 _minPrice, string memory _imgSrcLink, string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists, uint256 _req) external onlyApprovedAddresses{
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        auctionSettings[_auctionId].projectName = _projectName;
        auctionSettings[_auctionId].startTime = _startTime;
        auctionSettings[_auctionId].dutchPriceRate = _dutchRate;
        auctionSettings[_auctionId].dutchTimeRate = _timeRate;
        auctionSettings[_auctionId].startPrice = _startPrice;
        auctionSettings[_auctionId].minPrice = _minPrice;
        auctionSettings[_auctionId].imgSrc = _imgSrcLink;
        auctionSettings[_auctionId].discordLink = _discordLink;
        auctionSettings[_auctionId].twitterLink = _twitterLink;
        auctionSettings[_auctionId].maxWhitelists = _maxWhitelists;
        auctionSettings[_auctionId].req = _req;
    }
    
    function removeAuction(uint256 _auctionId) external onlyApprovedAddresses{
        delete auctionExists[auctionSettings[_auctionId].projectName];
        auctionSettings[_auctionId].exists = false;
    }
    
    function removeAuctions(uint256[] calldata _auctionIds) external onlyApprovedAddresses{
        for(uint i = 0; i < _auctionIds.length; i++){
            delete auctionExists[auctionSettings[_auctionIds[i]].projectName];
            auctionSettings[_auctionIds[i]].exists = false;
        }
    }

    function getAuction(uint256 _auctionId) external view returns (Auction memory){
        return auctionSettings[_auctionId];
    }
    
    function getAuctionName(uint256 _auctionId) external view returns (string memory){
        return auctionSettings[_auctionId].projectName;
    }
    
    function getAuctionState(uint256 _auctionId) public view returns (State){
        if(!auctionSettings[_auctionId].exists) return State.REMOVED;
        if(block.timestamp >= auctionSettings[_auctionId].startTime){
            if( getAuctionWhitelists(_auctionId).length < auctionSettings[_auctionId].maxWhitelists){
                return State.OPEN;
            }
            else{
                return State.CLOSED;
            }
        }
        else{
            return State.UPCOMING;
        }
    }
    
    function getAuctionWhitelists(uint256 _auctionId) public view returns (address [] memory){
        return whitelists[_auctionId];
    }
    
    function getCurrentPrice(uint256 _auctionId) public view returns (uint256){
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        if(auctionSettings[_auctionId].auctionType == 1){   
            if(block.timestamp < auctionSettings[_auctionId].startTime){
                return auctionSettings[_auctionId].startPrice;
            }
            uint256 reduction = (block.timestamp - auctionSettings[_auctionId].startTime) / auctionSettings[_auctionId].dutchTimeRate
            * auctionSettings[_auctionId].dutchPriceRate;
            uint256 newPrice =  auctionSettings[_auctionId].startPrice >= reduction ? 
            (auctionSettings[_auctionId].startPrice - reduction) : 0;
            return newPrice >= auctionSettings[_auctionId].minPrice ? newPrice : auctionSettings[_auctionId].minPrice;
        }
        else{    
            return auctionSettings[_auctionId].startPrice;
        }
    }
    
    function isWhitelisted(address _wallet, uint256 _auctionId) public view returns (bool) {
        for (uint i = 0; i < whitelists[_auctionId].length; i++) {
            if (whitelists[_auctionId][i] == _wallet) {
                return true;
            }
        }
        return false;
    }
   
    function countTotalOpened() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.OPEN){
                count++;
            }
        }
        return count;
    }
    
    function countTotalClosed() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.CLOSED){
                count++;
            }
        }
        return count;
    }
   
    function countTotalUpcoming() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.UPCOMING){
                count++;
            }
        }
        return count;
    }
    
    function countTotalRemoved() public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i < totalAuctions; i++){
            if(getAuctionState(i) == State.REMOVED){
                count++;
            }
        }
        return count;
    }
    
    function getAuctionsOpened() public view returns (Auction[] memory){
        Auction[] memory opened = new Auction[](countTotalOpened());
        uint i =0;
        for(uint f = totalAuctions; f > 0; f--){
            if(getAuctionState(f-1) == State.OPEN){
                opened[i] = auctionSettings[f-1];
                i++;
            }
        }
        return opened;
    }
    
    function getAuctionsClosed() public view returns (Auction[] memory){
        Auction[] memory closed = new Auction[](countTotalClosed());
        uint i =0;
        for(uint f = totalAuctions; f > 0; f--){
            if(getAuctionState(f-1) == State.CLOSED){
                closed[i] = auctionSettings[f-1];
                i++;
            }
        }
        return closed;
    }
    
    function getAuctionsUpcoming() public view returns (Auction[] memory){
        Auction[] memory upcoming = new Auction[](countTotalUpcoming());
        uint i =0;
        for(uint f = totalAuctions; f > 0; f--){
            if(getAuctionState(f-1) == State.UPCOMING){
                upcoming[i] = auctionSettings[f-1];
                i++;
            }
        }  
        return upcoming;
    }
    
    function getXAuctions(uint256 _start, uint256 _x, address _wallet) external view returns 
    (AllInfoRequest[] memory, AllInfoRequest[] memory, AllInfoRequest[] memory){
        Auction[] memory opened = getAuctionsOpened();
        Auction[] memory closed = getAuctionsClosed();
        Auction[] memory upcoming = getAuctionsUpcoming();
        AllInfoRequest[] memory Xopened = new AllInfoRequest[](_x);
        AllInfoRequest[] memory Xclosed = new AllInfoRequest[](_x);
        AllInfoRequest[] memory Xupcoming = new AllInfoRequest[](upcoming.length);
        uint t = 0;
        uint256 i;
        for(i = _start; i < _x + _start; i++){
            if(i >= opened.length){
                break;
            }
            Xopened[t].auction = opened[i];
            Xopened[t].wlArray = getAuctionWhitelists(opened[i].id);
            Xopened[t].price = getCurrentPrice(opened[i].id);
            Xopened[t].isWL = isWhitelisted(_wallet,opened[i].id);
            t++;
        }
        t = 0;
        for(i; i < _x + _start; i++){
            if(i >= (closed.length + opened.length)){
                break;
            }
            Xclosed[t].auction = closed[i-opened.length];
            Xclosed[t].wlArray = getAuctionWhitelists(closed[i-opened.length].id);
            Xclosed[t].price = getCurrentPrice(closed[i-opened.length].id);
            Xclosed[t].isWL = isWhitelisted(_wallet,closed[i-opened.length].id);
            t++;
        }
        Auction memory aux;
        uint256 time = block.timestamp;
        for(i = 0; i < upcoming.length; i++){
            for(uint j = 0; j < upcoming.length; j++){
                if((upcoming[i].startTime - time) < (upcoming[j].startTime - time)){
                    aux = upcoming[i];
                    upcoming[i] =  upcoming[j];
                    upcoming[j] = aux;
                }
            }
        }
        for(i = 0; i < upcoming.length; i++){
            Xupcoming[i].auction = upcoming[i];
            Xupcoming[i].wlArray = getAuctionWhitelists(upcoming[i].id);
            Xupcoming[i].price = getCurrentPrice(upcoming[i].id);
            Xupcoming[i].isWL = isWhitelisted(_wallet,upcoming[i].id);
        }
        return (Xopened, Xclosed, Xupcoming);
    }

    function setDependencies(address _loveAddress, address _firepitAddress) external onlyOwner{
        loveContract = LOVE(_loveAddress);
        firepitContract = Firepit(_firepitAddress);
    }
  
    function updateSigner(address _newSigner) external onlyOwner{
        signer = _newSigner;
    }

    function setApprovedAddresses(address _approvedAddress, bool _set) public onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
}