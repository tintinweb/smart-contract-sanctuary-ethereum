// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    import "IERC721.sol";
    import "IERC721Receiver.sol";
    import "IERC20.sol";
    import "Ownable.sol";
    import "IERC721Enumerable.sol";
    

    contract Stake is Ownable, IERC721Receiver{

    IERC20 public token;
    IERC721 public nft;
    
    // Contract Addresses
    address aterium_nft_Contract = 0xb28aB0b494988f85AAb81123b36fa464A122b281;
    address ater_token_Contract = 0x3f7bF11f4Dba7FcBF0E357dbeeEc667F67Fa6F6d;

    // Mapping 
    mapping(address => mapping(uint256 => uint256)) public tokenStakedTime;
    mapping(address => mapping(uint256 => uint256)) public tokenStakedDuration;
    mapping(uint256 => address) public stakedTokenOwner;
    mapping(address => uint256[]) public stakedTokens;

  
    constructor(){
    nft = IERC721(aterium_nft_Contract);
    token = IERC20(ater_token_Contract);
    }

    function stakeNFT(uint256 _tokenID) public payable{
    require(nft.ownerOf(_tokenID) == msg.sender, "Not the owner");
    stakedTokens[msg.sender].push(_tokenID);
 
    stakedTokenOwner[_tokenID] = msg.sender;
    tokenStakedTime[msg.sender][_tokenID] = block.timestamp;
    nft.safeTransferFrom(msg.sender,address(this),_tokenID,"0x00");

    }

    function unstakeNFT(uint256 _tokenID) public payable{

    nft.safeTransferFrom(address(this), msg.sender, _tokenID,"0x00");
    claimRewards(_tokenID);

    delete tokenStakedTime[msg.sender][_tokenID];
    delete stakedTokenOwner[_tokenID];   

    } 

     

    function claimRewards(uint256 _tokenID) public payable{

        tokenStakedDuration[msg.sender][_tokenID] = (block.timestamp - tokenStakedTime[msg.sender][_tokenID]);

        if (tokenStakedDuration[msg.sender][_tokenID] >= 86400 ){
            
        uint256 rewardRelease = (tokenStakedDuration[msg.sender][_tokenID] * 50 * 10 ** 18) / 86400;
        require(token.balanceOf(address(this)) >= rewardRelease);

        token.transfer(msg.sender,rewardRelease);

        tokenStakedTime[msg.sender][_tokenID] = block.timestamp;

        }


    }

    function getRewards(uint256 _tokenID) public returns(uint256 availableRewards){

    tokenStakedDuration[msg.sender][_tokenID] = (block.timestamp - tokenStakedTime[msg.sender][_tokenID]);
    return (tokenStakedDuration[msg.sender][_tokenID] * 50 * 10 ** 18) / 86400;


    }
    
    function getMyStakedTokens() public view returns (uint256[] memory allMyTokens){

        return stakedTokens[msg.sender];

     
    }


   function getAllStakedTokens(address _tokenOwner) view public onlyOwner returns (uint256[] memory allTokens) {

        return stakedTokens[_tokenOwner];

    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4){
    return this.onERC721Received.selector;
    }

    function setNFTContract(address _aterium_nft_Contract) public onlyOwner{
    nft = IERC721(_aterium_nft_Contract);

    }
  
    function setTokenContract(address _ater_token_Contract) public onlyOwner{
    token = IERC20(_ater_token_Contract);

    }
}