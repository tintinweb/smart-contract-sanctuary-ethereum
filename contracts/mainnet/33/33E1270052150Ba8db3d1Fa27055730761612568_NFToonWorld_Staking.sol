// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    import "IERC721.sol";
    import "IERC721Receiver.sol";
    import "IERC20.sol";
    import "Ownable.sol";
    import "IERC721Enumerable.sol";
    

    contract NFToonWorld_Staking is Ownable, IERC721Receiver{

    IERC20 public token;
    IERC721 public nft;

    uint256[] public stakedItems;
    uint256 public decimalNumber = 9;
    uint256 public rewardsAmount = 10;
    uint256 public rewardsCircle = 86400;
    uint256 public rewardsRate = 86400;

    uint256 public sweatshirts = 10000;
    uint256 public tShirts = 7500;
    uint256 public seatAtToonHall = 10000;
    uint256 public createACustomSticker = 5000;
    uint256 public writeYourStory = 20000;
    uint256 public featureYourNFTInComic = 25000;
    uint256 public orderCount;
    uint256 public sentOrderCount;

    Order[] public order;
    Order[] public sentOrders;

    // Contract Addresses
    address _nft_Contract =  0x8335f5bB8e0c79C17b0895446A67f24A6D45741D;
    address _token_Contract = 0xb91342EA719Cd1Ca6eA9E3341863aEf7956d0cA5;

    // Mapping 
    mapping(address => mapping(uint256 => uint256)) public tokenStakedTime;
    mapping(address => mapping(uint256 => uint256)) public tokenStakedDuration;
    mapping(uint256 => address) public stakedTokenOwner;
    mapping(address => uint256[]) public stakedTokens;
    mapping(address => uint256) public countofMyStakedTokens;
    mapping(address => mapping(uint256 => uint256)) public tokenRewards;

    struct Order {
        uint256 orderNumber;
        uint256 orderTime;
        address owner;
        uint256 categoryNumber;
        string emailAddress;       
        uint256 quantity;
        uint256 paidAmount;
    }
    
    constructor(){
    nft = IERC721(_nft_Contract);
    token = IERC20(_token_Contract);
    }

    function stakeNFT(uint256 _tokenID) public {
        require(nft.ownerOf(_tokenID) == msg.sender, "Not the owner");
        stakedTokens[msg.sender].push(_tokenID);
        countofMyStakedTokens[msg.sender]++;

        uint256 length = stakedTokens[msg.sender].length;

        if(stakedTokens[msg.sender].length != countofMyStakedTokens[msg.sender]){
            stakedTokens[msg.sender][countofMyStakedTokens[msg.sender]-1] = stakedTokens[msg.sender][length-1];
            delete stakedTokens[msg.sender][length-1];
        }
    
        stakedTokenOwner[_tokenID] = msg.sender;
        tokenStakedTime[msg.sender][_tokenID] = block.timestamp;
        nft.safeTransferFrom(msg.sender,address(this),_tokenID,"0x00");

    }

    function batchStakeNFT(uint256[] memory _tokenIDs) public {
        
        for(uint256 x = 0; x <  _tokenIDs.length ; x++){
            stakeNFT(_tokenIDs[x]);

        }

    }

    function buyItem(uint256 itemCategoryNumber, string memory email, uint256 quantity) public payable {
           uint256 paid;    
         
           if(itemCategoryNumber == 1){
           require(token.balanceOf(msg.sender) >= quantity * sweatshirts * 10**decimalNumber); 
           token.transferFrom(msg.sender, address(this), quantity * sweatshirts * 10**decimalNumber);       
           paid = quantity * sweatshirts * 10**decimalNumber; 
        }

          if(itemCategoryNumber == 2){
           require(token.balanceOf(msg.sender) >= quantity * tShirts * 10**decimalNumber); 
           token.transferFrom(msg.sender, address(this), quantity * tShirts * 10**decimalNumber);
           paid = quantity * tShirts * 10**decimalNumber;
        }

          if(itemCategoryNumber == 3){
           require(token.balanceOf(msg.sender) >= quantity * seatAtToonHall * 10**decimalNumber); 
           token.transferFrom(msg.sender, address(this), quantity * seatAtToonHall * 10**decimalNumber);
           paid = quantity * seatAtToonHall * 10**decimalNumber;
        }

          if(itemCategoryNumber == 4){
           require(token.balanceOf(msg.sender) >= quantity * createACustomSticker * 10**decimalNumber); 
           token.transferFrom(msg.sender, address(this), quantity * createACustomSticker * 10**decimalNumber);
           paid = quantity * createACustomSticker * 10**decimalNumber;
        }

          if(itemCategoryNumber == 5){
           require(token.balanceOf(msg.sender) >= quantity * writeYourStory * 10**decimalNumber); 
           token.transferFrom(msg.sender, address(this), quantity * writeYourStory * 10**decimalNumber);
           paid = quantity * writeYourStory * 10**decimalNumber;
        }

          if(itemCategoryNumber == 6){
           require(token.balanceOf(msg.sender) >= quantity * featureYourNFTInComic * 10**decimalNumber); 
           token.transferFrom(msg.sender, address(this), quantity * featureYourNFTInComic * 10**decimalNumber);
           paid = quantity * featureYourNFTInComic * 10**decimalNumber;
        }

        Order memory newOrder = Order(orderCount, block.timestamp, msg.sender, itemCategoryNumber, email, quantity, paid);

        orderCount++;    

        order.push(newOrder);
    } 

    function recordSentOrders(uint256 orderNumber) public onlyOwner{
        sentOrders.push(order[orderNumber]);
        delete order[orderNumber];

        sentOrderCount++;
    } 
        
    function unstakeNFT(uint256 _tokenID) public {

        nft.safeTransferFrom(address(this), msg.sender, _tokenID,"0x00");
        claimRewards(_tokenID);

        delete tokenStakedTime[msg.sender][_tokenID];
        delete stakedTokenOwner[_tokenID]; 

        for(uint256 i = 0; i < countofMyStakedTokens[msg.sender]; i++){
            if(stakedTokens[msg.sender][i] == _tokenID){    
            countofMyStakedTokens[msg.sender] = countofMyStakedTokens[msg.sender] - 1;


                for(uint256 x = i; x < countofMyStakedTokens[msg.sender]; x++){                   
                stakedTokens[msg.sender][x] = stakedTokens[msg.sender][x+1];
                }

                delete stakedTokens[msg.sender][countofMyStakedTokens[msg.sender]];

                           
            }
        }
    } 

    function batchUnstakeNFT(uint256[] memory _tokenIDs) public{

        for(uint256 x = 0; x <  _tokenIDs.length ; x++){
            unstakeNFT(_tokenIDs[x]);

        }
    }

    function batchClaimRewards(uint256[] memory _tokenIDs) public {

        for(uint256 x = 0; x <  _tokenIDs.length ; x++){
            claimRewards(_tokenIDs[x]);
        }
        
    }


     function claimRewards(uint256 _tokenID) public {

        tokenStakedDuration[msg.sender][_tokenID] = (block.timestamp - tokenStakedTime[msg.sender][_tokenID]);

        if (tokenStakedDuration[msg.sender][_tokenID] >= rewardsCircle ){
            
        uint256 rewardRelease = (tokenStakedDuration[msg.sender][_tokenID] * rewardsAmount * 10 ** decimalNumber) / rewardsRate;
        if(token.balanceOf(address(this)) >= rewardRelease){
            token.transfer(msg.sender,rewardRelease);
            tokenStakedTime[msg.sender][_tokenID] = block.timestamp;
        }

        }
    }
  
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4){
    return this.onERC721Received.selector;
    }

    function setNFTContract(address _nftContract) public onlyOwner{
    nft = IERC721(_nftContract);

    }
  
    function setTokenContract(address _tokenContract) public onlyOwner{
    token = IERC20(_tokenContract);

    }
    
    function setDecimalNumber(uint256 _decimalNumber) public onlyOwner{
    decimalNumber = _decimalNumber;

    }

    function setRewardsCircle(uint256 _rewardsCircle) public onlyOwner{
    rewardsCircle = _rewardsCircle;

    }

    function setRewardsAmount(uint256 _rewardsAmount) public onlyOwner{
    rewardsAmount = _rewardsAmount;

    }

    function setRewardsRate(uint256 _rewardsRate) public onlyOwner{
    rewardsRate = _rewardsRate;

    }

    function setSweatshirts (uint256 _sweatshirts ) public onlyOwner{
    sweatshirts = _sweatshirts ;

    }

    function setTShirts (uint256 _tShirts  ) public onlyOwner{
    tShirts = _tShirts  ;

    }

     function setFeatureYourNFTInComic (uint256 _featureYourNFTInComic ) public onlyOwner{
    featureYourNFTInComic = _featureYourNFTInComic ;

    }

    function setSeatAtToonHall (uint256 _seatAtToonHall ) public onlyOwner{
    seatAtToonHall = _seatAtToonHall ;

    }

    function setCreateACustomSticker (uint256 _createACustomSticker ) public onlyOwner{
    createACustomSticker = _createACustomSticker ;

    }

    function setWriteYourStory (uint256 _writeYourStory ) public onlyOwner{
    writeYourStory = _writeYourStory ;

    }

    function tokenWithdrawal() public onlyOwner{
        token.transfer(msg.sender,token.balanceOf(address(this)));

    }
}