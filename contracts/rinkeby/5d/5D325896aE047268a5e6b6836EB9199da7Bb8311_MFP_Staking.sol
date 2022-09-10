// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    import "IERC721.sol";
    import "IERC721Receiver.sol";
    import "IERC20.sol";
    import "Ownable.sol";
    import "IERC721Enumerable.sol";
    

    contract MFP_Staking is Ownable, IERC721Receiver{

    IERC20 public token;
    IERC721 public nft;

    uint256[] public stakedItems;
    uint256 public decimalNumber = 9;
    uint256 public rewardsAmount = 150;
    uint256 public rewardsCircle = 2592000;
    uint256 public rewardsRate = 2592000;
    
    // Contract Addresses
    address _nft_Contract = 0xabFb724542fF231d8C57299836D8c1F35C660648;
    address _token_Contract = 0x181487D497029BFB19e098e85848A291D38fbB95; //0xa7CF4F442970902b3190168f24b33e3c14E1CdB0;

    // Mapping 
    mapping(address => mapping(uint256 => uint256)) public tokenStakedTime;
    mapping(address => mapping(uint256 => uint256)) public tokenStakedDuration;
    mapping(uint256 => address) public stakedTokenOwner;
    mapping(address => uint256[]) public stakedTokens;
    mapping(address => uint256) public countofMyStakedTokens;
    mapping(address => mapping(uint256 => uint256)) public tokenRewards;
  
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

    function tokenWithdrawal() public onlyOwner{
        token.transfer(msg.sender,token.balanceOf(address(this)));

    }
}