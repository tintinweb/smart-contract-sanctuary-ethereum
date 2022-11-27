// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    import "IERC721.sol";
    import "IERC721Receiver.sol";
    import "IERC20.sol";
    import "Ownable.sol";
    import "IERC721Enumerable.sol";
    
    contract SocietyOfPepeStaking is Ownable, IERC721Receiver{

    IERC721 public nft;       
    uint256 public countOfOverallStakers;
    uint256 public merchCount;
    uint256 public merchTimePeriod = 6048000; // 70 days
    uint256 public raffleBonus = 3;
    uint256 public raffleMinusBonus = 2;

    // Contract Addresses
    address _nft_Contract = 0x90E35EacCD5c80085F25BAc90B48B11424567c55;

    // Mapping 
    mapping(address => mapping(uint256 => uint256)) public tokenStakedTime;
    mapping(address => mapping(uint256 => uint256)) public tokenStakedDuration;
    mapping(uint256 => address) public stakedTokenOwner;
    mapping(address => uint256[]) public stakedTokens;
    mapping(address => uint256) public countofMyStakedTokens;
    mapping(uint256 => address) public stakers;
    mapping(uint256 => string) public merchRequestDiscord;
    mapping(uint256 => address) public merchRequestUser;
    mapping(uint256 => mapping(uint256 => address)) public merchRequestUserBytokenID;
    mapping(uint256 => uint256) public tokenStakedDurationbyID;
    mapping(uint256 => uint256) public merchCountbyTokenID;
    mapping(address => mapping(uint256 => bool)) public isStaked;
    mapping(address => uint256) public raffleEntries;


    constructor(){
    nft = IERC721(_nft_Contract);
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

        stakers[countOfOverallStakers] = msg.sender;    
        countOfOverallStakers++;
        isStaked[msg.sender][_tokenID] = true;
        raffleEntries[msg.sender] = raffleEntries[msg.sender] + raffleBonus;
     

    }

    function batchStakeNFT(uint256[] memory _tokenIDs) public {
        
        for(uint256 x = 0; x <  _tokenIDs.length ; x++){
            stakeNFT(_tokenIDs[x]);

        }

    }

    function requestMerch(string memory discordID, uint256 _tokenID) public {

        tokenStakedDuration[msg.sender][_tokenID] = block.timestamp - tokenStakedTime[msg.sender][_tokenID];
        tokenStakedDurationbyID[_tokenID] = tokenStakedDurationbyID[_tokenID] + tokenStakedDuration[msg.sender][_tokenID];
        require(tokenStakedDurationbyID[_tokenID]  >= merchTimePeriod,"Staked Time is not enough");
        merchRequestDiscord[merchCount] = discordID;
        merchRequestUser[merchCount] = msg.sender; 
        merchRequestUserBytokenID[merchCountbyTokenID[_tokenID]][_tokenID] = msg.sender;


        delete tokenStakedDurationbyID[_tokenID];
        delete tokenStakedDuration[msg.sender][_tokenID];
        tokenStakedTime[msg.sender][_tokenID] = block.timestamp;

        merchCountbyTokenID[_tokenID]++;
        merchCount++;
    }
        
    function unstakeNFT(uint256 _tokenID) public {

        nft.safeTransferFrom(address(this), msg.sender, _tokenID,"0x00");
        tokenStakedDuration[msg.sender][_tokenID] = block.timestamp - tokenStakedTime[msg.sender][_tokenID];
        tokenStakedDurationbyID[_tokenID] = tokenStakedDurationbyID[_tokenID] + tokenStakedDuration[msg.sender][_tokenID];

        delete tokenStakedTime[msg.sender][_tokenID];
        delete stakedTokenOwner[_tokenID]; 
        isStaked[msg.sender][_tokenID] = false;

        raffleEntries[msg.sender] = raffleEntries[msg.sender] - raffleMinusBonus;


        for(uint256 i = 0; i < countofMyStakedTokens[msg.sender]; i++){
            if(stakedTokens[msg.sender][i] == _tokenID){    
            countofMyStakedTokens[msg.sender] = countofMyStakedTokens[msg.sender] - 1;


                for(uint256 x = i; x < countofMyStakedTokens[msg.sender]; x++){                   
                stakedTokens[msg.sender][x] = stakedTokens[msg.sender][x+1];
                }

                delete stakedTokens[msg.sender][countofMyStakedTokens[msg.sender]];
                           
            }
        }

        countOfOverallStakers--;
    } 

    function batchUnstakeNFT(uint256[] memory _tokenIDs) public{

        for(uint256 x = 0; x <  _tokenIDs.length ; x++){
            unstakeNFT(_tokenIDs[x]);

        }
    }


    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4){
    return this.onERC721Received.selector;
    }

    function setNFTContract(address _nftContract) public onlyOwner{
    nft = IERC721(_nftContract);
    }

    function setMerchTimePeriod(uint256 _merchTimePeriod) public onlyOwner{
    merchTimePeriod = _merchTimePeriod;
    }

    function setRaffleBonus(uint256 _raffleBonus) public onlyOwner{
    raffleBonus = _raffleBonus;
    }

    function setRaffleMinusBonus(uint256 _raffleMinusBonus) public onlyOwner{
    raffleMinusBonus = _raffleMinusBonus;
    }

    function withdrawal() public onlyOwner {

    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);

    }
}