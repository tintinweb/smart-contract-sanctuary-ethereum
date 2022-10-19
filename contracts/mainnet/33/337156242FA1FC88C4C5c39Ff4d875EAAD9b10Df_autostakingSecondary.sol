//SPDX-License-Identifier: Copyright Grobat
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Strings.sol";
import "./Counters.sol";



interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function addShare(address shareholder) external payable;
    function deposit() external payable;
    function process(uint256 gas) external;
    function getUnpaidEarnings(address autostakingcontract) external view returns (uint256);
    function distributeToken() external;
    function setContractInitial(address contadmin) external payable;
    function setMintedOut(address mintedOutContract)external;
    function addMintingShare(address NftContract) external payable;
}

interface IAutostakingContract {
    function getMaxSupply() external view returns (uint max);
    function getMinted() external view returns (uint minted);
    function getStoragePrice() external view  returns (uint storagePrice);
    function getMintPrice() external view returns (uint mintPrice);
    function addTokenToBuy(address TokenToAdd, uint percent) external;
    function setFeeReciever(address reciever)external;
    function excludeFromrewardMultiple(address[] calldata Adds) external;
    function getReflectionBalances() external view returns(uint256);
    function claimRewards() external;
    function recoverStuckToken (IBEP20 token) external;
    function claimTokens () external;
    function mintMany(uint256 quantity) external payable;
    function setMintingEnabled(bool Allowed) external;
    function claimRewardsInToken() external;
    function deposit()external payable;
}

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - token ID and URI autogenerationA
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract autostakingSecondary is Context, AccessControlEnumerable, ERC721Enumerable, ERC721URIStorage, IAutostakingContract{
  using Counters for Counters.Counter;

  struct  buyableTokens{
    address buyableToken;
    uint256 percentage;
  }

  struct  wallets{
    address walletAddress;

    uint256 percentage;
  }
  
  
  Counters.Counter public _tokenIdTracker;

  string private _baseTokenURI;
  string public _contractMeta;
  uint private _tokenPrice = 25 * 10**16;
  uint private _price = 1 * 10**16; 
  uint public maxSupply = 1000;
  address private _admin;
  address public _feeReciever;
  uint256 public _distributorFee = 10; // 10% static;
  IDEXRouter public router;
  bool public canMint = false;
  uint public mintPercentage;
  uint256 public totalReflectionVolume;
  uint256 public totalCollected;
  uint256 public artistPercent = 3;
  uint256 devpercent = 2;
  uint256 public reflectPercent = 25;
  bool public isAutostaking = true;
  address WETH;
  address deadAddress = 0x000000000000000000000000000000000000dEaD;
  address public artistFeeReciever = 0x08f5bCD7421Fc071E7A916Ed77003B1cf78F6fAa;
  address public devFeeReciever = 0x3A0Cb1D6B195Ea497B060Cc99A292E37E5D27529;
  address public marketingReciever;
  
  buyableTokens[] public tokensToBuy;
  wallets[] public walletsToSend;
  
  uint256 public reflectionBalance;
  uint256 public totalDividend;

  mapping(uint256 => uint256) lastDividendAt;
  mapping (uint256 => address ) public creator;
  mapping (address => bool) public excludedFromRewards; 

  uint256 private mintAMount = 100;
  uint256 public totalrewards = 0;



  constructor(string memory name, string memory symbol, uint mintPrice, address admin, uint max) ERC721(name, symbol) {
      _tokenPrice = mintPrice;
      maxSupply = max;
      _admin = admin;
      router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Mainnet
      _setupRole(DEFAULT_ADMIN_ROLE, admin);
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      WETH = address(router.WETH());
  }

  receive () external payable {
    if(_tokenIdTracker.current() >= maxSupply){
      payable(marketingReciever).transfer(msg.value * 20 /100);
      reflectDividend(msg.value * 80 /100);
    }
  }

  function contractURI() public view returns (string memory) {
        return _contractMeta;
  }

  function SetcontractURI(string calldata URI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: only the distributor can add this meta");
        _contractMeta = URI;
  }

  function getMinted() external view override returns (uint minted){
    return _tokenIdTracker.current();
  }

  function getMaxSupply() external view override returns (uint max){
    return maxSupply;
  }


  function getStoragePrice() external view override returns (uint storagePrice){
    return _price;
  }

  function getMintPrice() external view override returns (uint mintPrice){
    return _tokenPrice;
  }

  function setAdditionalAdmin(address newAdmin) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to add admins");
    _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
  } 


  function excludeFromrewardMultiple(address[] calldata Adds) external override {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have distributor role to add exclusions");
    for(uint i = 0; i< Adds.length; i++){
      excludedFromRewards[Adds[i]] = true;
    }
  } 

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

   function setFeeReciever(address reciever)public override {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to change fee reciever");
    _feeReciever = reciever;
  }

  function setBaseURI(string memory baseURI) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to change base URI");
    _baseTokenURI = baseURI;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to change token URI");
    _setTokenURI(tokenId, _tokenURI);
  }

  function setMintingEnabled(bool Allowed) external override {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to change minting ability");
    canMint = Allowed;
  }


  function getServiceFee() external view returns(uint256){
    return _price;
  }
 
   function mint() external payable {
    require(canMint, "autostaking: minting currently disabled");
    require(msg.value >= (_tokenPrice), "autostaking: must send correct price");
    require((_tokenIdTracker.current() + 1) < maxSupply, "autostaking: all autostaking have been minted");

    _mint(msg.sender, _tokenIdTracker.current());
    creator[_tokenIdTracker.current()] = msg.sender;
    lastDividendAt[_tokenIdTracker.current()] = totalDividend;
    _setTokenURI(_tokenIdTracker.current(), string(abi.encodePacked(Strings.toString(_tokenIdTracker.current()), ".json")));
    _tokenIdTracker.increment();
    splitBalance(1);
  }

  function mintMany(uint256 quantity) external payable override {
    require(canMint, "autostaking: minting currently disabled");
    require (quantity < 11, "autostaking: minting more than 10 is prohibited");
    require(msg.value >= (quantity * _tokenPrice), "autostaking: must send correct price");
    require((_tokenIdTracker.current() + quantity) < maxSupply, "autostaking: all autostaking have been minted");
    for(uint i = 0; i < quantity; i++){
      _mint(msg.sender, _tokenIdTracker.current());
      creator[_tokenIdTracker.current()] = msg.sender;
      lastDividendAt[_tokenIdTracker.current()] = totalDividend;
      _setTokenURI(_tokenIdTracker.current(), string(abi.encodePacked(Strings.toString(_tokenIdTracker.current()), ".json")));
      _tokenIdTracker.increment();
    }
    splitBalance(quantity);
  }
  
  function mintMultiples(address[] calldata recipients)public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to initial mint");
        for (uint256 i = 0; i < recipients.length; i++){
      _mint(recipients[i], _tokenIdTracker.current());
      creator[_tokenIdTracker.current()] = recipients[i];
      lastDividendAt[_tokenIdTracker.current()] = totalDividend;
      _setTokenURI(_tokenIdTracker.current(), string(abi.encodePacked(Strings.toString(_tokenIdTracker.current()), ".json")));
      _tokenIdTracker.increment();
    }
  }

  function NftCreator(uint256 tokenId) public view returns(address){
    return creator[tokenId];
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    return ERC721URIStorage._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    if (totalSupply() > tokenId) claimReward(tokenId);
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function currentRate() public view returns (uint256){
      if(totalSupply() == 0) return 0;
      return reflectionBalance/totalSupply();
  }

  function claimRewards() public override{
    uint count = balanceOf(msg.sender);
    uint256 total = 0;
    for(uint i=0; i < count; i++){
        uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
        //claimReward(tokenId);
        total += getReflectionBalance(tokenId);
        lastDividendAt[tokenId] = totalDividend;
    }
    if(total > 0){
        payable(msg.sender).transfer(total);
        reflectionBalance -= total;
    }
  }

  function claimRewardsInToken() external override{
    uint count = balanceOf(msg.sender);
    uint256 total = 0;
    for(uint i=0; i < count; i++){
        uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
        total += getReflectionBalance(tokenId);
        lastDividendAt[tokenId] = totalDividend;
    }
    if(total > 0){
        address[] memory path = new address[](2);
        for(uint i = 0; i < tokensToBuy.length; i++){
            uint ToSend = total/tokensToBuy.length;
            path[0] = router.WETH();
            path[1] = address(tokensToBuy[i].buyableToken);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ToSend}(
              0,
              path,
              msg.sender,
              block.timestamp + 20
            );
          }
        reflectionBalance -= total;
    }
  }

  function claimReward(uint tokenId) internal {
    uint256 total = getReflectionBalance(tokenId);
    if(total > 0){
      reflectionBalance -= total;
      if(!excludedFromRewards[ownerOf(tokenId)]){
          address[] memory path = new address[](2);
            for(uint i = 0; i < tokensToBuy.length; i++){
            uint ToSend = total/tokensToBuy.length;
            path[0] = router.WETH();
            path[1] = address(tokensToBuy[i].buyableToken);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ToSend}(
              0,
              path,
              ownerOf(tokenId),
              block.timestamp + 20
            );
          }
      }else{
        reflectDividend(total);
      }
      lastDividendAt[tokenId] = totalDividend;
    }
  }

  function getReflectionBalances() public view override returns(uint256) {
    uint count = balanceOf(msg.sender);
    uint256 total = 0;
    for(uint i=0; i < count; i++){
        uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
        total += getReflectionBalance(tokenId);
    }
    return total;
  }

  function claimTokens () external override {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to claim the balance");
    // make sure we capture all BNB that may or may not be sent to this contract
    payable(_admin).transfer(address(this).balance - reflectionBalance);
  }

  function setArtistFeeReciever (address receiver) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to set artist wallet");
    // make sure we capture all BNB that may or may not be sent to this contract
    artistFeeReciever = receiver;
  }

  function setMarketingFeeReciever (address receiver) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to set artist wallet");
    // make sure we capture all BNB that may or may not be sent to this contract
    
    marketingReciever = receiver;
  }

  function recoverStuckToken (IBEP20 token) external override{
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to claim the balance");
    // make sure we capture all BNB that may or may not be sent to this contract
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  function getReflectionBalance(uint256 tokenId) public view returns (uint256){
      return totalDividend - lastDividendAt[tokenId];
  }

  function deposit()public payable override {
    reflectDividend(msg.value);
  }

  function addTokenToBuy(address TokenToAdd, uint percent) external override {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: only the admin can add a token");
    buyableTokens memory token;
    token.buyableToken = TokenToAdd;
    token.percentage = percent;
    tokensToBuy.push(token);
  }

  function removeTokenToBuy(address TokenToRemove) external returns(bool success){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to remove payable token");
        for(uint i = 0; i < tokensToBuy.length; i++){
            if(address(tokensToBuy[i].buyableToken) == address(TokenToRemove)){
            tokensToBuy[i] = tokensToBuy[tokensToBuy.length - 1];
            tokensToBuy.pop();
            return true;
            }
        }
        return false;
  }

  function addWalletToBuy(address wallet, uint percent) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: only the admin can add a token");
    wallets memory walletToBuy;
    walletToBuy.walletAddress = wallet;
    walletToBuy.percentage = percent;
    walletsToSend.push(walletToBuy);
  }

  function removeWalletToBuy(address ToRemove) external returns(bool success){
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to remove payable token");
      for(uint i = 0; i < walletsToSend.length; i++){
          if(address(walletsToSend[i].walletAddress) == address(ToRemove)){
          walletsToSend[i] = walletsToSend[walletsToSend.length - 1];
          walletsToSend.pop();
          return true;
          }
      }
      return false;
  }

  function setReflectPercent(uint256 percentage) external{
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "autostaking: must have admin role to set reflect percent");
    reflectPercent = percentage;
  }

  function splitBalance(uint256 amount) private {
      uint tokenAmount = amount * _tokenPrice; // get the total token price to sell for reflection purchases
      uint totaltoDistribute = tokenAmount;
      uint256 artistEarnings = totaltoDistribute * artistPercent /100;
      payable(artistFeeReciever).transfer(artistEarnings);
      uint256 devValue = totaltoDistribute * devpercent /100;
      payable(devFeeReciever).transfer(devValue);
      reflectDividend(totaltoDistribute * reflectPercent /100);
      for(uint i = 0; i < walletsToSend.length; i++){
        uint ToSend = totaltoDistribute * walletsToSend[i].percentage /100;
        payable(walletsToSend[i].walletAddress).transfer(ToSend);
      }
  }

  function reflectDividend(uint256 amount) private {
    reflectionBalance  = reflectionBalance + amount;
    totalDividend = totalDividend + (amount/totalSupply());
    totalCollected += amount;
    totalReflectionVolume += amount;
  } 
}