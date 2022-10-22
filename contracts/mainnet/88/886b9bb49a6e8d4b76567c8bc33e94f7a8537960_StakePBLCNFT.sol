pragma solidity ^0.8.17;
// SPDX-License-Identifier: Unlicense

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./IUniswapV2Router.sol";
import "./ERC1155Holder.sol";
import "./ReentrancyGuard.sol";

contract StakePBLCNFT is Ownable, ERC1155Holder, ReentrancyGuard{
    
      using SafeMath for uint256;

      /**
      * NFT contract address
      */
      IERC1155 public stakingNft;

      /**
      *State (ERC20) token address
      */
      IERC20 public rewardingToken;


      /**
      * state token divisible upto rewardingTokenDecimals
      */
      uint256 public rewardingTokenDecimals;

      /**
      * usdc token divisible upto usdcDecimal
      */
      uint256 public usdcMultiplier = 1_000_000;

      /**
      * stable coin to calculate price in USD
      */
      IERC20 public usdc;

      /**  uniswap v2 router to calculate the token's reward on run-time
      *   usd balance equalent token
      */
      IUniswapV2Router02 public uniswapRouter;

      /**
      * wallet from where contract will transfer State reward
      */
      address private rewardingTokenWallet;

      /* per day reward and multiple of 100
      *  16.18 x 100
      */
      uint256 public rewardAPY = 1618;


      /**
      * struct to hold the info of staked NFTs
      */
      struct nftInfo {
        uint256 tokenId;
        address staker;
        uint256 stakeTime;
        uint256 category;
        uint256 amount;
      }

      /**
      * if staking is allowed, state to flip staking
      */
      bool public stakeAllowed = true;

      /**
      * if UnStake is allowed state to flip staking
      */
      bool public unstakeAllowed = true;

      mapping (address =>  mapping (uint256 => nftInfo)) public staked;

      /**
      * category like broze, silver, gold, platinum asigned a number
      */
      mapping (uint256 => uint256) public category;


      /**
      * events fire after every stake and unstake
      */
      event Stake(address staker, uint256 indexed tokenId, uint256 category, uint256 amount, uint256 stakeTime);
      event Unstake(address unstaker , uint256 tokenId, uint256 reward);
      event Withdraw(address indexed withdrawer);
      event WithdrawToken(address indexed withdrawer, uint256 amount);


      /**
      * modifier to check if the NFTs are approved to stake
      */
      modifier isApproved() {
      require(stakingNft.isApprovedForAll(_msgSender(),address(this)), "NFTs Not Approved");
        _;
      }


      constructor() {
      stakingNft = IERC1155(0xfBaE39320AA6E4Aee6829489aeD6eb2CC32a6459);
      rewardingToken = IERC20(0x00C2999c8B2AdF4ABC835cc63209533973718eB1);
      rewardingTokenDecimals = rewardingToken.decimals();
      rewardingTokenWallet = 0x61d966e1a54Ff9C6B4cd083B5Ec968B366850f65;
      uniswapRouter =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);


      category[35765170590814674817329738340066840990845959557561780372227731964376303796239]=1;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796229]=10;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796230]=50;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796231]=100;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796232]=500;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796233]=1_000;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796234]=10_000;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796235]=50_000;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796236]=100_000;
      category[35765170590814674817329738340066840990845959557561780372227731964376303796225]=1_000_000;
    }
    
    /**
      * Function to show the rewarding token's wallet
      */
    function rewardingWalletGet() public view returns (address){
      return rewardingTokenWallet;
    }

    /**
      * Function to change the APY, must be multiplied by 100
      * it takes one integer value
      * only owner can call this function
      */
    function rewardPerDaySet(uint256 value) public onlyOwner{
    /**
      * mutiply value with 100.
      */
     rewardAPY = value;
    }


    /**
      * setter function for rewarding token address, it takes one token address
      * only owner can call this function
      */
    function changeRewardingToken(address newToken) public onlyOwner {
      rewardingToken = IERC20(newToken);
    }

    /**
      * setter for rewarding token's wallet address, it takes one wallet address
      * only owner can call this function
      */
    function changeRewardingTokenWallet(address newWallet) public onlyOwner {
      rewardingTokenWallet = newWallet;
    }
  
    /**
      * internal Stake NFT function, it takes one NFT Id and its amount
      */
    function _stake(uint256 tokenId , uint256 amount) internal isApproved() {
      require(stakeAllowed , "staking is stopped");
      require(stakingNft.balanceOf(_msgSender(), tokenId) >= amount, "Must Own Nft");
      
      nftInfo storage info = staked[_msgSender()][tokenId];

      stakingNft.safeTransferFrom(_msgSender() , address(this) , tokenId, amount, '');

      info.tokenId = tokenId;
      info.amount = amount;
      info.staker = _msgSender();
      info.stakeTime = block.timestamp;
      info.category = category[tokenId];

      emit Stake(_msgSender() , tokenId, category[tokenId], amount, block.timestamp);
    }


    /**
      * internal unstake NFTs , it takes NFT Id
      */
    function _unstake(uint256 tokenId) internal nonReentrant{
      require(unstakeAllowed , "unstaking not allowed right now");
      require(stakingNft.balanceOf(address(this), tokenId) > 0, "Contract Must Own Nft");
      nftInfo storage info = staked[_msgSender()][tokenId];
      require(info.tokenId == tokenId, "Not Staked");
      require(info.staker == _msgSender(), "Not Your staked Token");

      uint256 stakedtime = block.timestamp.sub(info.stakeTime);
      stakedtime = stakedtime / 1 seconds;

      uint256 reward = rewardAPY.mul(category[tokenId]).mul(stakedtime).mul(usdcMultiplier).div(10000).div(365);

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


    /**
      * get the price of token, input amount of USDC and addresses of udsc and state token, it will return
      * usdc amount equal state tokens
      */
    function priceOfToken(uint256 amount, address[] memory path) public view returns (uint[] memory amounts){
        amounts =  uniswapRouter.getAmountsOut(amount, path);
        return amounts;
    }

 
 
    /**
      * function to check the current reward of a NFT. it takes one nft id and the account address of staker
      * and return number of state token reward for that staked NFT
      */ 
    function checkReward(address staker, uint256 tokenId) public view returns (uint256){
      nftInfo memory info = staked[staker][tokenId];

      uint256 stakedtime = block.timestamp.sub(info.stakeTime);
      stakedtime = stakedtime / 1 seconds;

      uint256 reward = rewardAPY.mul(category[info.tokenId]).mul(stakedtime).mul(usdcMultiplier).div(10000).div(365);

      address[] memory path;
        path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(rewardingToken);

      uint256[] memory price = priceOfToken(reward, path);
      return price[1];
    }

    

    /**
      * public method to stake single NFTs, it takes one nft id and amount of that nft as input
      */
    function stake(uint256 tokenId, uint256 amount) public nonReentrant{
      _stake(tokenId, amount);
    }

    /**
      * public method to Unstake single NFTs, it takes nft id as input
      */
    function unstake(uint256 tokenId) public nonReentrant{
      _unstake(tokenId); 
    }


    /**
      * public method to stake more than one NFTs, it takes one array of NFT ids and one array for their amounts.
      * it will call internal stake fucntion
      */
    function stakeMany(uint256[] memory tokenIds , uint256[] memory amount) public nonReentrant{
      for(uint256 i = 0; i< tokenIds.length;i++){
        _stake(tokenIds[i] , amount[i]);
      }
    }


    /**
      * public method to Unstake all NFTs, it takes one array nft ids
      */
    function unstakeMany(uint256[] memory tokenIds) public {
      for(uint256 i = 0; i< tokenIds.length;i++){
        _unstake(tokenIds[i]);
      }
    }


    /**
      * public function to check how many tokens are set as a reward, tokens allocated for reward.
      */
    function pendingRewards() public view returns (uint256){
      return rewardingToken.allowance(rewardingTokenWallet , address(this));
    }

    /**
      * public method flip stake state, it takes one true/false boolean value.
      * only owner can call this function
      */
    function setStakeAllowed(bool state) public onlyOwner {
        stakeAllowed = state;
    }

    /**
      * public method flip Unstake state, it takes one true/false boolean value.
      * only owner can call this function
      */
    function setUnStakeAllowed(bool state) public onlyOwner {
        unstakeAllowed = state;
    }


    /**
      * NFT contract address setter,  it takes one NFT contract address
      * only owner can call this function
      */
    function setNFTadress(IERC1155 nft) public onlyOwner {
        stakingNft = nft;
    }
    

    /**
      * withdraw tokens stuck in the smart contract, pass address of receiver and token address
      * only owner can call this function
      */
    function withdrawAnyToken(address _recipient, address _IERC20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20(_IERC20address).transfer(_recipient, _amount); //use of the BEP20 traditional transfer
        return true;
    }


    /**
      * transfer coin stuck in the smart contract,  it takes one account address.
      * only owner can call this function
      */
    function transferXS(address payable rec) public onlyOwner {
        rec.transfer(address(this).balance);
    }


    /**
      * withdraw NFTs stuck in the smart contract, it takes one address and one nft id 
      * only owner can call this function
      */
    function withdrawUselessNft(address _recipient, uint256 tokenId, uint256 amount) public onlyOwner returns(bool) {
      stakingNft.safeTransferFrom(address(this), _recipient, tokenId, amount, '');(address(this),_recipient, tokenId);
      return true;
    }

    receive() external payable{
    }
}