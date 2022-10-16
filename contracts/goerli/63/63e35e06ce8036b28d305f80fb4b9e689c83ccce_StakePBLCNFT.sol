pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./IUniswapV2Router.sol";
import "./ERC1155Holder.sol";

contract StakePBLCNFT is Ownable, ERC1155Holder{
    
      using SafeMath for uint256;

      // NFT contract address
      IERC1155 public stakingNft;

      // State (ERC20) token address
      IERC20 public rewardingToken;

      // token divisible upto rewardingTokenDecimals
      uint256 public rewardingTokenDecimals;

      // stable coin to calculate price in USD
      IERC20 public usdc;

      /**  uniswap v2 router to calculate the token's reward on run-time
      usd balance equalent token
      */
      IUniswapV2Router02 public uniswapRouter;

      // wallet from where contract will transfer State reward
      address private rewardingTokenWallet;

      /* per day reward and multiple of 100
      16.18 x 100
      */
      uint256 public rewardAPY = 1618;

      // struct to hold the info of staked NFTs
      struct nftInfo {
        uint256 tokenId;
        address staker;
        uint256 stakeTime;
        uint256 category;
        uint256 amount;
      }

      // if staking is allowed
      bool public stakeAllowed = true;

       // if UnStake is allowed
      bool public unstakeAllowed = true;

      mapping (uint256 => nftInfo) public staked;

      // category like broze, silver, gold, platinum
      mapping (uint256 => uint256) public category;


      event Stake(address staker, uint256 indexed tokenId, uint256 category, uint256 amount, uint256 stakeTime);
      event Unstake(address unstaker , uint256 tokenId, uint256 reward);
      event Withdraw(address indexed withdrawer);
      event WithdrawToken(address indexed withdrawer, uint256 amount);

      // to check if the NFTs are approved to stake
      modifier isApproved() {
      require(stakingNft.isApprovedForAll(_msgSender(),address(this)), "NFTs Not Approved");
        _;
      }


      constructor() {
      stakingNft = IERC1155(0x0608D1609C7A29F594A73525E33e3b4256DD33a6);
      rewardingToken = IERC20(0x1395dfd352E3925621c60db6C53f35beB93D1A3E);
      rewardingTokenDecimals = rewardingToken.decimals();
      rewardingTokenWallet = 0x7Ef8E5643424bed763dD1BdE66d4b2f79F9EDcd8;
      uniswapRouter =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      usdc = IERC20(0x6E65f9A2Ed4B190b7487bD41639DeBfc08E4D441);

      // stakingNft = IERC1155(0xd9145CCE52D386f254917e481eB44e9943F39138);
      // rewardingToken = IERC20(0x1395dfd352E3925621c60db6C53f35beB93D1A3E);
      // // rewardingTokenDecimals = rewardingToken.decimals();
      // rewardingTokenWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
      // uniswapRouter =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      // usdc = IERC20(0x6E65f9A2Ed4B190b7487bD41639DeBfc08E4D441);

      category[1]=1;
      category[2]=2;
      category[3]=3;
      category[4]=4;
      category[5]=5;
      category[6]=6;
      category[7]=7;
      category[8]=8;
      category[9]=9;
      category[10]=10;
    }
    
    function rewardingWalletGet() public view onlyOwner returns (address){
      return rewardingTokenWallet;
    }

    // Multiple of 100
    function rewardPerDaySet(uint256 value) public onlyOwner{
        // mutiply value with 100.
     rewardAPY = value;
    }

    // setter for rewarding token address
    function changeRewardingToken(address newToken) public onlyOwner {
      rewardingToken = IERC20(newToken);
    }
    // setter for rewarding token's wallet address
    function changeRewardingTokenWallet(address newWallet) public onlyOwner {
      rewardingTokenWallet = newWallet;
    }
  
    // internal Stake NFT function
    function _stake(uint256 tokenId , uint256 amount) internal isApproved() {
      require(stakeAllowed , "staking is stopped");
      require(stakingNft.balanceOf(_msgSender(), tokenId) >= amount, "Must Own Nft");
      
      nftInfo storage info = staked[tokenId];
      require(info.tokenId == 0, "Already Staked");
      // data
      stakingNft.safeTransferFrom(_msgSender() , address(this) , tokenId, amount, '');
      // (_msgSender() , address(this) , tokenId);

      info.tokenId = tokenId;
      info.amount = amount;
      info.staker = _msgSender();
      info.stakeTime = block.timestamp;
      info.category = category[tokenId];

      emit Stake(_msgSender() , tokenId, category[tokenId], amount, block.timestamp);
    }

    // internal unstake NFTs
    function _unstake(uint256 tokenId) internal {
      require(unstakeAllowed , "unstaking not allowed right now");
      require(stakingNft.balanceOf(address(this), tokenId) > 0, "Contract Must Own Nft");
      nftInfo storage info = staked[tokenId];
      require(info.tokenId == tokenId, "Not Staked");
      require(info.staker == _msgSender(), "Not Your staked Token");

      uint256 stakedtime = block.timestamp.sub(info.stakeTime);
      stakedtime = stakedtime / 1 seconds;

      uint256 reward = rewardAPY.mul(category[tokenId]).mul(stakedtime).div(10000);

    //   price / amount
      reward = reward * 1000_000;
      address[] memory path;
        path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(rewardingToken);

      uint256[] memory price = priceOfToken(reward, path);

      if(price[1] > 0 && price[1] <= pendingRewards() ){
        rewardingToken.transferFrom(rewardingTokenWallet , _msgSender() , price[1]);
      }
      else{
        require(false, "Pending Rewards Not Allocated");
      }

      stakingNft.safeTransferFrom(address(this), _msgSender(), tokenId, info.amount, '');
      info.tokenId = 0;
      info.staker = address(0);
      info.category = 0;
      emit Unstake(_msgSender() , tokenId,  price[1]);
    }

    // get the price of token
    function priceOfToken(uint256 amount, address[] memory path) public view returns (uint[] memory amounts){
        amounts=  uniswapRouter.getAmountsOut(amount, path);
        // emit WithdrawToken(msg.sender, amounts);
        return amounts;
    }

      // internal unstake NFTs
    function checkReward(uint256 tokenId) public view returns (uint256){
      nftInfo memory info = staked[tokenId];

      uint256 stakedtime = block.timestamp.sub(info.stakeTime);
      stakedtime = stakedtime / 1 seconds;

      uint256 reward = rewardAPY.mul(category[tokenId]).mul(stakedtime).div(10000);

    //   price / amount
      reward = reward * 1000_000;
      address[] memory path;
        path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(rewardingToken);

      uint256[] memory price = priceOfToken(reward, path);
      return price[1];
    }

    
    // public method to stake NFTs
    function stake(uint256 tokenId, uint256 amount) public{
      _stake(tokenId, amount);
    }
    // public method to Unstake NFTs
    function unstake(uint256 tokenId) public {
      _unstake(tokenId); 
    }
    // public method to stake more than one NFTs
    function stakeMany(uint256[] memory tokenIds , uint256[] memory amount) public {
      for(uint256 i = 0; i< tokenIds.length;i++){
        _stake(tokenIds[i] , amount[i]);
      }
    }
    // public method to Unstake all NFTs
    function unstakeMany(uint256[] memory tokenIds) public {
      for(uint256 i = 0; i< tokenIds.length;i++){
        _unstake(tokenIds[i]);
      }
    }

    // tokens allocated for reward
    function pendingRewards() public view returns (uint256){
      return rewardingToken.allowance(rewardingTokenWallet , address(this));
    }
    // public method flip stake state
    function setStakeAllowed(bool state) public onlyOwner {
        stakeAllowed = state;
    }
    // public method flip Unstake state
    function setUnStakeAllowed(bool state) public onlyOwner {
        unstakeAllowed = state;
    }

    // NFT contract address setter
    function setNFTadress(IERC1155 nft) public onlyOwner {
        stakingNft = nft;
    }
    
    // withdraw tokens stuck in the smart contract
    function withdrawAnyToken(address _recipient, address _BEP20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20(_BEP20address).transfer(_recipient, _amount); //use of the BEP20 traditional transfer
        return true;
    }

    // transfer coin stuck in the smart contract
    function transferXS(address payable rec) public onlyOwner {
        rec.transfer(address(this).balance);
    }

    // withdraw NFTs stuck in the smart contract
    function withdrawUselessNft(address _recipient, uint256 tokenId) public onlyOwner returns(bool) {
      nftInfo storage info = staked[tokenId];
      require(info.tokenId == 0, "Staked");
      require(info.staker == address(0), "Token is staked by someone");
      stakingNft.safeTransferFrom(address(this), _recipient, tokenId, 1, '');(address(this),_recipient, tokenId);
      return true;
    }

    receive() external payable{
    }
}