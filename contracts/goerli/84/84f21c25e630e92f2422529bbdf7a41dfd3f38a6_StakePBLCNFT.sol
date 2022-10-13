pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Ownable.sol";
import "./SafeMath.sol";

import "./IERC1155.sol";
import "./IERC20.sol";
import "./IUniswapV2Router.sol";
import "./ERC1155.sol";

contract StakePBLCNFT is Ownable, ERC1155{
    
      using SafeMath for uint256;

      IERC1155 public stakingNft;
      IERC20 public rewardingToken;
      uint256 public rewardingTokenDecimals;
      IERC20 public usdc;

      IUniswapV2Router02 public uniswapRouter;

      address private rewardingTokenWallet;
    //   per day reward and multiple of 100
      uint256 public rewardAPY = 1618;

      struct nftInfo {
        uint256 tokenId;
        address staker;
        uint256 stakeTime;
        uint256 category;
        uint256 amount;
      }

      bool public stakeAllowed = true;
      bool public unstakeAllowed = true;
      mapping (uint256 => nftInfo) public staked;
      mapping (uint256 => uint256) public category;


      event Stake(address staker, uint256 indexed tokenId, uint256 category, uint256 amount, uint256 stakeTime);
      event Unstake(address unstaker , uint256 tokenId);
      event Withdraw(address indexed withdrawer);
      event WithdrawToken(address indexed withdrawer, uint256 amount);

    modifier isApproved() {
      require(stakingNft.isApprovedForAll(_msgSender(),address(this)), "NFTs Not Approved");
        _;
    }


      constructor() ERC1155("") {
      // stakingNft = IERC1155(0x2fD2Eb2E2d2053B1806be9D2F3A3Cb15426D10B1);
      // rewardingToken = IERC20(0x1395dfd352E3925621c60db6C53f35beB93D1A3E);
      // rewardingTokenDecimals = rewardingToken.decimals();
      // rewardingTokenWallet = 0x7Ef8E5643424bed763dD1BdE66d4b2f79F9EDcd8;
      // uniswapRouter =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      // usdc = IERC20(0x6E65f9A2Ed4B190b7487bD41639DeBfc08E4D441);

      stakingNft = IERC1155(0xd9145CCE52D386f254917e481eB44e9943F39138);
      rewardingToken = IERC20(0x1395dfd352E3925621c60db6C53f35beB93D1A3E);
      // rewardingTokenDecimals = rewardingToken.decimals();
      rewardingTokenWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
      uniswapRouter =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      usdc = IERC20(0x6E65f9A2Ed4B190b7487bD41639DeBfc08E4D441);

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

    function changeRewardingToken(address newToken) public onlyOwner {
      rewardingToken = IERC20(newToken);
    }

    function changeRewardingTokenWallet(address newWallet) public onlyOwner {
      rewardingTokenWallet = newWallet;
    }
    
 function onERC1155Received(
          address _operator
        , address 
        , uint256 
        , uint256 _value
        , bytes memory 
    )
        public
        returns (
            bytes4 selector
        )
    {
       

        return this.onERC1155Received.selector;
    }

    /**
     * @notice Batch sending of ERC1155s is not supported as it would require a more complex payment
     *         processing system. This function is only here to satisfy the ERC1155Receiver interface.
     *         It will revert if called.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory 
    )
        public 
        pure
        returns(
            bytes4
        )
    {
        /// @dev Revert because this model does not support multiple tokens
        revert("ERC721Receivable::onERC1155BatchReceived: batch transfer feature not supported.");
    }

     function _stake(uint256 tokenId , uint256 amount) internal isApproved() {
      require(stakeAllowed , "staking is stopped");
      require(stakingNft.balanceOf(_msgSender(), tokenId) >= amount, "Must Own Nft");
      
      nftInfo storage info = staked[tokenId];
      require(info.tokenId == 0, "Already Staked");
    //   data
      stakingNft.safeTransferFrom(_msgSender() , address(this) , tokenId, amount, '');
    //   (_msgSender() , address(this) , tokenId);

      info.tokenId = tokenId;
      info.amount = amount;
      info.staker = _msgSender();
      info.stakeTime = block.timestamp;
      info.category = category[tokenId];

      emit Stake(_msgSender() , tokenId, category[tokenId], amount, block.timestamp);
    }

    function _unstake(uint256 tokenId) internal {
      require(unstakeAllowed , "unstaking not allowed right now");
      require(stakingNft.balanceOf(address(this), tokenId) > 0, "Contract Must Own Nft");
      nftInfo storage info = staked[tokenId];
      require(info.tokenId == tokenId, "Not Staked");
      require(info.staker == _msgSender(), "Not Your staked Token");

      uint256 stakedtime = block.timestamp.sub(info.stakeTime);
      stakedtime = stakedtime / 1 days;

      uint256 reward = rewardAPY.mul(category[tokenId]).mul(stakedtime).div(10000);

    //   price / amount
      // reward = priceOfToken().div(reward);
      address[] memory path;
        path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(rewardingToken);

      reward = reward.div(priceOfToken(reward, path));

      if(reward > 0 && reward <= pendingRewards() ){
        rewardingToken.transferFrom(rewardingTokenWallet , _msgSender() , reward);
      }
      else{
        require(false, "Pending Rewards Not Allocated");
      }

      stakingNft.safeTransferFrom(address(this), _msgSender(), tokenId, info.amount, '');
      info.tokenId = 0;
      info.staker = address(0);
      info.category = 0;
      emit Unstake(_msgSender() , tokenId);
    }

    function priceOfToken(uint256 amount, address[] memory path) internal view returns(uint256){
        uniswapRouter.getAmountsOut(amount, path);
        return 2;
    }

    function stake(uint256 tokenId, uint256 amount) public{
      _stake(tokenId, amount);
    }

    function unstake(uint256 tokenId) public {
      _unstake(tokenId); 
    }

    function stakeMany(uint256[] memory tokenIds , uint256[] memory amount) public {
      for(uint256 i = 0; i< tokenIds.length;i++){
        _stake(tokenIds[i] , amount[i]);
      }
    }

    function unstakeMany(uint256[] memory tokenIds) public {
      for(uint256 i = 0; i< tokenIds.length;i++){
        _unstake(tokenIds[i]);
      }
    }

    function pendingRewards() public view returns (uint256){
      return rewardingToken.allowance(rewardingTokenWallet , address(this));
    }

    function setStakeAllowed(bool state) public onlyOwner {
        stakeAllowed = state;
    }

    function setUnStakeAllowed(bool state) public onlyOwner {
        unstakeAllowed = state;
    }

    function setNFTadress(IERC1155 nft) public onlyOwner {
        stakingNft = nft;
    }
    
    function withdrawAnyToken(address _recipient, address _BEP20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20(_BEP20address).transfer(_recipient, _amount); //use of the BEP20 traditional transfer
        return true;
    }

    function transferXS(address payable rec) public onlyOwner {
        rec.transfer(address(this).balance);
    }

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