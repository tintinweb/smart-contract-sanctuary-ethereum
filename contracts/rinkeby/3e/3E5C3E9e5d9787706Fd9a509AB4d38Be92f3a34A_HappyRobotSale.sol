// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./HappyRobotNFT.sol";
import "./HappyRobotWhitelistToken.sol";

contract HappyRobotSale is Ownable {
  
    uint8 constant GENERATION_SIZE = 2;   

    // gen indexes
    uint8 constant GEN1_INDEX = 1;
    uint8 constant GEN2_INDEX = 2;

    uint8 constant MIDDLE_FLOOR = 8;
    uint8 constant firstLevelNeurons = 30;
    uint8 constant secondLevelNeurons = 50;

    // sale status constants
    uint8 constant SALE_STATUS_NONE = 0;
    uint8 constant SALE_STATUS_PRE = 1;
    uint8 constant SALE_STATUS_PUB = 2;

    uint8 private maxNFTPerWallet = 2;

    address private nftAddress;
    address private wlTokenAddress;

    uint256 private nftMintFee = 0.1 ether;

    uint8 private genIndex = GEN1_INDEX;
    uint8 private saleStatus = SALE_STATUS_NONE;

    address[] private whitelist;
    address[] private giftWhitelist;
    mapping(address => uint32) neuronsMap;

    mapping(address => mapping(uint8 => uint16)) nftMintsMap;

    mapping(uint8 => uint16) totalMintedNFTs;

    address payable private walletMaster = payable(0x6510711132d1c1c20BcA3Add36B8ad0fb6E73AFA);
    address payable constant public walletDevTeam = payable(0x52BD82C6B851AdAC6A77BC0F9520e5A062CD9a78);
    address payable constant public walletArtist = payable(0x22d57ccD4e05DD1592f52A4B0f909edBB82e8D26);

    event ChangedSaleStatus(uint8 _genIndex, uint8 _saleStatus);
    event MintedNFT(address _owner, uint16 _quantity, uint256 _totalNFT);
    event ExchangedNFT(address _owner, uint16 _quantity, uint256 _totalNFT, uint256 _totalWhitelistToken);

    /**
    * Require msg.sender to be the master
    */
    modifier onlyMaster() {
        require(isMaster(msg.sender), "Happy Robot: You are not a Master");
        _;
    }
    /**
    * Require msg.sender to be the dev team
    */
    modifier onlyDev() {
        require(msg.sender == walletDevTeam, "Happy Robot: You are not Dev team");
        _;
    }

    /**
    * Require msg.sender to be not the master or dev team
    */
    modifier onlyNotMaster() {
        require(!isMaster(msg.sender), "Happy Robot: You are a Master");
        _;
    }

    /**
    * require not none sale status
    */
    modifier onlySaleStatus() {
        require(saleStatus != SALE_STATUS_NONE, "Happy Robot: It is not sale period");
        _;
    }

    /**
    * require none sale status
    */
    modifier onlyNonSaleStatus() {
        require(saleStatus == SALE_STATUS_NONE, "Happy Robot: It is sale period");
        _;
    }

    constructor(address _nftAddress, address _wlTokenAddress, uint8 _saleStatus) {
        nftAddress = _nftAddress;
        wlTokenAddress = _wlTokenAddress;
        saleStatus = _saleStatus;
    }

    /**
    * get nft contract address
    * @return nft contract address
    */
    function getNFTAddress() public view returns (address) {
        return nftAddress;
    }

    /**
    * get whitelist contract address
    * @return whitelist contract address
    */
    function getWLTokenAddress() public view returns (address) {
        return wlTokenAddress;
    }

    /**
    * set whitelist contract address
    * @param _wlTokenAddress whitelist contract address
    */
    function setWLTokenAddress(address _wlTokenAddress) public onlyMaster {
        wlTokenAddress = _wlTokenAddress;
    }

    /**
    * get master wallet address
    * @return walletMaster wallet master address
    */
    function getMasterWalletAddress() public view returns (address) {
        return walletMaster;
    }

    /**
    * set master wallet address
    * @param _walletMaster master wallet address
    */
    function setMasterWalletAddress(address _walletMaster) public onlyMaster {
        walletMaster = payable(_walletMaster);
    }

    /**
    * change ownership for whitelist contract address
    * @param _newAddress new owner address of whitelist contract
    */
    function changeOwnershipOfWLToken(address _newAddress) public onlyMaster onlyDev {
        HappyRobotWhitelistToken(wlTokenAddress).transferOwnership(_newAddress);
    }

    /**
    * get sale status
    * @return 0: pre sale, 1: public sale
    */
    function getSaleStatus() public view returns (uint8) {
        return saleStatus;
    }

    /**
    * set sale status
    * @param _saleStatus sale status
    */
    function setSaleStatus(uint8 _saleStatus) public onlyMaster {
        require(_saleStatus <= SALE_STATUS_PUB, "Happy Robot: You can only set the value in the range of 0 to 2.");
        saleStatus = _saleStatus;
    }

    /**
    * get generation index
    * @return 1: generation1, 2: generation2
    */
    function getGenerationIndex() public view returns (uint8) {
        return genIndex;
    }

    /**
    * set generation index
    * @param _genIndex generation index 1: generation1, 2: generation2
    */
    function setGenerationIndex(uint8 _genIndex) public onlyMaster {
        require(_genIndex == GEN1_INDEX || _genIndex == GEN2_INDEX, "Happy Robot: You can only set 1 or 2");
        genIndex = _genIndex;
    }

    /**
    * move the status to the gen1's public sale
    */
    function moveToGen1PreSale() public onlyMaster {
        require(genIndex == GEN1_INDEX && saleStatus == SALE_STATUS_NONE, "Happy Robot: Current status is not gen1's sale none.");
        saleStatus = SALE_STATUS_PRE;

        emit ChangedSaleStatus(genIndex, saleStatus);
    }

    /**
    * move the status to the gen1's public sale
    */
    function moveToGen1PublicSale() public onlyMaster {
        require(genIndex == GEN1_INDEX && saleStatus == SALE_STATUS_PRE, "Happy Robot: Current status is not gen1's presale.");
        saleStatus = SALE_STATUS_PUB;

        emit ChangedSaleStatus(genIndex, saleStatus);
    }

    /**
    * move the status to the gen2's pre sale
    */
    function moveToGen2PreSale() public onlyMaster {
        require(genIndex == GEN1_INDEX && saleStatus == SALE_STATUS_PUB, "Happy Robot: Current status is not gen1's public sale.");
        genIndex = GEN2_INDEX;
        saleStatus = SALE_STATUS_PRE;

        emit ChangedSaleStatus(genIndex, saleStatus);
    }

    /**
    * move the status to the gen2's public sale
    */
    function moveToGen2PublicSale() public onlyMaster {
        require(genIndex == GEN2_INDEX && saleStatus == SALE_STATUS_PRE, "Happy Robot: Current status is not gen2's presale.");
        saleStatus = SALE_STATUS_PUB;

        emit ChangedSaleStatus(genIndex, saleStatus);
    }

    /**
    * set whitelist token uri
    * @param _uri whitelist token uri
    */
    function setWLTokenURI(string memory _uri) public onlyMaster { 
        HappyRobotWhitelistToken(wlTokenAddress).setURI(_uri);
    }

    /**
    * update the base URL of nft's URI
    * @param _newBaseURI New base URL of token's URI
    */
    function setNFTURI(string memory _newBaseURI) public onlyMaster {
        HappyRobotNFT(nftAddress).setBaseURI(_newBaseURI);
    }

    /**
    * get account is master or not
    * @param _account address
    * @return true or false
    */
    function isMaster(address _account) public view returns (bool) {
        return walletMaster == payable(_account) || walletDevTeam == payable(_account);
    }

    /**
    * get max nfts per wallet
    * @return max nfts per wallet
    */
    function getMaxNFTPerWallet() public view returns (uint8) {
        return maxNFTPerWallet;
    }

    /**
    * set max nfts per wallet
    * @param _maxNFTPerWallet max nfts per wallet
    */
    function setMaxNFTPerWallet(uint8 _maxNFTPerWallet) public {
        maxNFTPerWallet = _maxNFTPerWallet;
    }

    /**
    * get nft mint fee
    * @return nft mint fee
    */
    function getNFTMintFee() public view returns (uint256) {
        return nftMintFee;
    }

    /**
    * set nft mint fee
    * @param _fee nft mint fee
    */
    function setNFTMintFee(uint256 _fee) public onlyMaster {
        nftMintFee = _fee;
    }

    /**
    * get number of total minted nfts for generation index
    * @param _genIndex generation index
    * @return number of total minted nfts for generation index
    */
    function getTotalMintedNFTs(uint8 _genIndex) public view returns (uint16) {
        return totalMintedNFTs[_genIndex];
    }

    /**
    * get number of minted nft for account and generation
    * @param _account address
    * @param _genIndex generation index
    * @return number of minted nft for account and generation
    */
    function getNFTMints(address _account, uint8 _genIndex) public view returns (uint16) {
        return nftMintsMap[_account][_genIndex];
    }

    /**
    * update the floor information
    * @param _id id of NFT
    */
    function unlockFloor(uint256 _id) public {
        HappyRobotNFT nft = HappyRobotNFT(nftAddress);

        require(nft.ownerOf(_id) == msg.sender, "Happy Robot: You can unlock for only your NFT.");

        uint8 currentFloor = nft.getCurrentFloor(_id);

        // to unlock the next floor
        uint8 reqNeurons = firstLevelNeurons;
        if (currentFloor > MIDDLE_FLOOR) 
            reqNeurons = secondLevelNeurons;

        unchecked {
            uint32 availableNeurons = neuronsMap[msg.sender] + nft.getNeurons(_id);

            require(availableNeurons >= reqNeurons, "Happy Robot: Your neurons are not enough to unlock the level.");

            uint32 claimedNeurons = nft.claimNeurons(msg.sender, _id, reqNeurons);
        
            if (claimedNeurons < reqNeurons)
                neuronsMap[msg.sender] -= (reqNeurons - claimedNeurons);
        }
        
        nft.unlockFloor(msg.sender, _id);
    }

    /**
    * claim neurons
    * @param _ids id list of NFT
    */
    function claimNeurons(uint256[] calldata _ids) public returns (uint32) {
        HappyRobotNFT nft = HappyRobotNFT(nftAddress);

        bool tokenOwnerChecked = true;
        for (uint8 i = 0; i < _ids.length; i++) {
            if (nft.ownerOf(_ids[i]) != msg.sender) {
                tokenOwnerChecked = false;
                break;
            }
        }

        require(tokenOwnerChecked, "You can claim neurons for only your NFTs.");

        for (uint8 i = 0; i < _ids.length; i++) {
            uint32 neurons = nft.getNeurons(_ids[i]);
            uint32 claimedNeurons = nft.claimNeurons(msg.sender, _ids[i], neurons);

            unchecked {
                neuronsMap[msg.sender] += claimedNeurons;
            }
        }

        return neuronsMap[msg.sender];
    }

    /**
    * get all neurons of address(include NFT neurons)
    * @param _account address
    * @return neurons of address + neurons of NFTs
    */
    function getAllNeurons(address _account) public view returns (uint32) {
        uint32 neurons = neuronsMap[_account];    // neurons of wallet address

        // get neurons of nfts and get total sum
        HappyRobotNFT nft = HappyRobotNFT(nftAddress);
        uint256[] memory tokenIds = nft.getTokenIdsOfOwner(_account);

        unchecked {
            for (uint16 i = 0; i < tokenIds.length; i++) {
                neurons += nft.getNeurons(tokenIds[i]);
            }
        }

        return neurons;
    }

    /**
    * get neurons of address
    * @param _account address
    * @return neurons of address
    */
    function getNeuronsForWallet(address _account) public view returns (uint32) {
        return neuronsMap[_account];    // neurons of wallet address
    }

    /**
    * get neurons of address
    * @param _account address
    * @param _id id of token
    * @return neurons of address
    */
    function getNeuronsToUnlock(address _account, uint256 _id) public view returns (uint32) {
        HappyRobotNFT nft = HappyRobotNFT(nftAddress);
        
        unchecked {
            return neuronsMap[_account] + nft.getNeurons(_id);    // neurons of wallet address + nft's neurons
        }
    }

    /**
    * get whitelist
    */
    function getWhitelist() public view returns (address[] memory) {
        return whitelist;
    }

    /**
    * check if _account is in the whitelist
    * @param _account address
    * @return 
    */
    function existInWhitelist(address _account) public view returns (bool) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _account)
                return true;
        }
        return false;
    }

    /**
    * add an address into the whitelist
    * @param _account address
    */
    function addToWhitelist(address _account) public onlyMaster {
        if (!existInWhitelist(_account))  whitelist.push(_account);
    }

    /**
    * remove an address into the whitelist
    * @param _account address
    */
    function removeFromWhitelist(address _account) public onlyMaster {
        // find index of _from
        uint256 index = 0xFFFF;
        uint256 len = whitelist.length;
        for (uint256 i = 0; i < len; i++) {
            if (whitelist[i] == _account) {
                index = i;
                break;
            }
        }

        // remove it
        if (index != 0xFFFF && len > 0) {
            whitelist[index] = whitelist[len - 1];
            whitelist.pop();
        }
    }

    /**
    * import an address list into the whitelist
    * @param _accountList address list
    */
    function importWhitelist(address[] calldata _accountList) public onlyMaster {
        delete whitelist;
        for (uint16 i = 0; i < _accountList.length; i++) {
            whitelist.push(_accountList[i]);
        }
    }

    /**
    * check if _account has gift
    * @param _account address
    * @return 
    */
    function hasGift(address _account) internal view returns (bool) {
        for (uint256 i = 0; i < giftWhitelist.length; i++) {
            if (giftWhitelist[i] == _account)
                return true;
        }
        return false;
    }

    /**
    * give a gift to _to
    * @param _to address
    */
    function addGift(address _to) public onlyMaster {
        if (!hasGift(_to))  giftWhitelist.push(_to);
    }

    /**
    * remove a gift from _from
    * @param _from address
    */
    function removeGift(address _from) internal {
        // find index of _from
        uint256 index = 0xFFFF;
        uint256 len = giftWhitelist.length;
        for (uint256 i = 0; i < len; i++) {
            if (giftWhitelist[i] == _from) {
                index = i;
                break;
            }
        }

        // remove it
        if (index != 0xFFFF) {
            giftWhitelist[index] = giftWhitelist[len - 1];
            giftWhitelist.pop();
        }
    }

    /**
    * check if mint is possible for generation index
    * @param _quantity quantity
    * @param _genIndex generation index
    * @return true or false
    */
    function canMintNFTForGeneration(uint8 _genIndex, uint16 _quantity) internal view returns (bool) {
        return HappyRobotNFT(nftAddress).canCreateToken(_genIndex, _quantity);
    }

    /**
    * check if mint is possible for account
    * @param _account account
    * @param _quantity quantity
    * @return true or false
    */
    function canMintNFTForAccount(address _account, uint16 _quantity) internal view returns (bool) {
        if (isMaster(_account)) return true;
        
        bool retValue = false;
        unchecked {
            uint16 balance = nftMintsMap[_account][GEN1_INDEX] + nftMintsMap[_account][GEN2_INDEX] + _quantity;
            if (uint8(balance) <= maxNFTPerWallet)
                retValue = true;
        }
        return retValue;
    }

    /**
    * mint a new NFT 
    * @param _quantity token quantity
    */
    function mintNFT(uint16 _quantity) external payable onlySaleStatus {

        require(canMintNFTForGeneration(genIndex, _quantity), "Happy Robot: Maximum NFT mint already reached for the generation");

        require(canMintNFTForAccount(msg.sender, _quantity), "Happy Robot: Maximum NFT mint already reached for the account");

        HappyRobotWhitelistToken whitelistToken = HappyRobotWhitelistToken(wlTokenAddress);
        bool hasWhitelistToken = whitelistToken.quantityOf(msg.sender) > 0;

        if (saleStatus == SALE_STATUS_PRE && !hasGift(msg.sender) && !isMaster(msg.sender)) {
            require(hasWhitelistToken || whitelistToken.existInMinters(msg.sender) || existInWhitelist(msg.sender), "Happy Robot: You should be in the whitelist or you should have a whitelist token");
        }

        HappyRobotNFT nft = HappyRobotNFT(nftAddress);

        // perform mint
        if (isMaster(msg.sender) || hasGift(msg.sender)) {   // free mint
            nft.mint(msg.sender, _quantity);

            // return back the ethers
            address payable caller = payable(msg.sender);
            caller.transfer(msg.value);

            removeGift(msg.sender);

        } else {
            require(msg.value >= nftMintFee * _quantity, "Happy Robot: Not enough ETH sent");

            // perform mint
            nft.mint(msg.sender, _quantity);

            unchecked {
                uint256 mintFee = nftMintFee * _quantity;

                uint256 feeForDev = (uint256)(mintFee / 200); // 0.5% to the dev
                walletDevTeam.transfer(feeForDev);

                uint256 feeForArtist = (uint256)(mintFee / 40); // 2.5% to the dev
                walletArtist.transfer(feeForArtist);

                // return back remain value
                uint256 remainVal = msg.value - mintFee;
                address payable caller = payable(msg.sender);
                caller.transfer(remainVal);
            }
        }

        unchecked {
            totalMintedNFTs[genIndex] += _quantity;
            nftMintsMap[msg.sender][genIndex] += _quantity;
        }

        // trigger nft token minted event
        emit MintedNFT(msg.sender, _quantity, nft.totalSupply());
    }

    /**
    * exchange NFTs with whitelist tokens
    * @param _quantity token quantity
    */
    function exchangeNFTWithWhitelistToken(uint8 _quantity) external onlySaleStatus {

        HappyRobotWhitelistToken whitelistToken = HappyRobotWhitelistToken(wlTokenAddress);
        require(whitelistToken.quantityOf(msg.sender) >= _quantity, "Happy Robot: Not enough HRF tokens to exchange");

        HappyRobotNFT nft = HappyRobotNFT(nftAddress);

        if (nft.isGen1SoldOut()) {
            require(canMintNFTForGeneration(GEN2_INDEX, _quantity), "Happy Robot: Maximum NFT mint already reached for the generation 2");
        }

        // perform mint
        nft.mint(msg.sender, _quantity);

        // burn whitelist token
        whitelistToken.burn(msg.sender, _quantity);

        // trigger nft token minted event
        emit ExchangedNFT(msg.sender, _quantity, nft.totalSupply(), whitelistToken.getTotalMinted());
    }

    /**
    * withdraw balance to only master wallet
    */
    function withdrawAll() external onlyMaster {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    /**
    * withdraw balance to only master wallet
    */
    function withdraw(uint256 _amount) external onlyMaster {
        require(address(this).balance >= _amount, "Happy Robot: Not enough balance to withdraw");

        address payable to = payable(msg.sender);
        to.transfer(_amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 * @title HappyRobotNFT
 * HappyRobotNFT - ERC721 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract HappyRobotNFT is ERC721A, Ownable {

  // max sizes for every generation
  uint16 public constant gen1MaxQuantity = 3333;
  uint16 public constant gen2MaxQuantity = 3334;
  
  uint8 constant startTimeErrLimit = 120;
  
  // constant value for every generation
  uint8 public constant GEN1_INDEX = 1;
  uint8 public constant GEN2_INDEX = 2;

  uint8 constant LAST_FLOOR = 10;

  /************************************** FOR TESTING ************************************/
  // uint16 constant DAYSTAMP_DIVIDE_VAL = 24 * 60 * 60;
  uint16 constant DAYSTAMP_DIVIDE_VAL = 60;
  
  // happy robot nft attributes
  struct Attribute {
    uint16  tokenId;
    uint32  neuronDayStamp; // day value of timestamp = timestamp / DAYSTAMP_DIVIDE_VAL,
                            // when minting NFT, this value is set with the day value of current timestamp
    uint8   currentFloor;   // current floor value: from 1 to 10
    uint24  totalTime;      // total seconds which the nft passed floors
    bool    locked;         // the flag if the floor is locked or unlocked
    uint32  secureVal;      // the value for preventing scamming
  }

  mapping(uint256 => Attribute) private attribute; // attribute of happy robot nft
  
  uint8 isReveal = 0;

  string private preRevealTokenUri;

  // base uri
  string private baseURI;

  address payable private walletMaster = payable(0x6510711132d1c1c20BcA3Add36B8ad0fb6E73AFA);
  address payable constant public walletDevTeam = payable(0x52BD82C6B851AdAC6A77BC0F9520e5A062CD9a78);

  event PassedFloor(uint256 _id, uint8 _floor, uint16 _passTime, uint24 _totalPassTime);

  constructor(string memory _preRevealTokenUri) ERC721A("Happy Robot", "HAPPYROBOT") {
    preRevealTokenUri = _preRevealTokenUri;
  }

  /**
  * Require msg.sender to be the master
  */
  modifier onlyMaster() {
    require(isMaster(msg.sender), "Happy Robot NFT: You are not a Master");
    _;
  }

  /**
  * get account is master or not
  * @param _account address
  * @return true or false
  */
  function isMaster(address _account) public view returns (bool) {
    return walletMaster == payable(_account) || walletDevTeam == payable(_account);
  }

  /**
   * Will update the base URL of token's URI
   * @param _newBaseURI New base URL of token's URI
   */
  function setBaseURI(string memory _newBaseURI) public onlyMaster {
    baseURI = _newBaseURI;
  }

  /**
   * get base uri 
   * @return base uri
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * Will update the pre reveal URL of tokens
   * @param _preRevealTokenUri New URL of token's URI
   */
  function setPreRevealTokenUri(string memory _preRevealTokenUri) public onlyMaster {
    preRevealTokenUri = _preRevealTokenUri;
  }

  /**
  * get token uri
  * @param _tokenId token id
  * @return token uri
  */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (isReveal == 0) return preRevealTokenUri;
    
    return ERC721A.tokenURI(_tokenId);
  }

  /**
   * Will update the pre reveal URL of tokens
   * @param _isReveal current state is 
   */
  function setRevealStatus(uint8 _isReveal) public onlyMaster {
    isReveal = _isReveal;
  }

  /**
    * start token id should be 1
    */
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
  * get gen1's quantity
  * @return gen1's quantity
  */
  function getGen1Quantity() public view returns (uint256) {
    if (totalSupply() >= gen1MaxQuantity)
      return gen1MaxQuantity;

    return totalSupply();
  }

  /**
  * get if generation 1 is sold out
  */
  function isGen1SoldOut() public view returns (bool) {
    return (totalSupply() >= gen1MaxQuantity);
  }

  /**
  * get gen2's quantity
  * @return gen2's quantity
  */
  function getGen2Quantity() public view returns (uint256) {
    if (totalSupply() <= gen1MaxQuantity)
      return 0;

    unchecked {
      return totalSupply() - gen1MaxQuantity;
    }
  }

  /**
  * get if generation 2 is sold out
  */
  function isGen2SoldOut() public view returns (bool) {
    return (getGen2Quantity() >= gen2MaxQuantity);
  }

  /**
   * Check if token can be created 
   * @param _genIndex generation index
   * @param _quantity quantity
   * @return true or false
   */
  function canCreateToken(uint8 _genIndex, uint16 _quantity) public view returns (bool) {

    unchecked {
      if (_genIndex == GEN1_INDEX) {
        if (getGen1Quantity() + _quantity >= gen1MaxQuantity)
          return false;

      } else if (_genIndex == GEN2_INDEX) {
        if (getGen2Quantity() + _quantity >= gen2MaxQuantity)
          return false;

      } else {
        return false;
      }
    }

    return true;
  }

  /**
   * reset attribute values for NFT
   * @param _id token id
   */
  function _resetAttribute(uint256 _id) internal {
    unchecked {
      uint32 neuronDayStamp = uint32(block.timestamp / DAYSTAMP_DIVIDE_VAL);
      Attribute memory attr = Attribute(uint16(_id), neuronDayStamp, 1, 0, true, 0);

      attribute[_id] = attr;
    }
  }

  /**
  * get token id list of owner
  * @param _owner the owner of token
  * @return token id list
  */
  function getTokenIdsOfOwner(address _owner) public view returns (uint256[] memory) {
    uint8 tokenCounter = 0;

    unchecked {
      // get counter of tokens
      for (uint256 i = _startTokenId(); i < _currentIndex; i++) {
        if (ownerOf(i) == _owner) {
          tokenCounter++;
        }
      }

      // configure token id list
      uint256[] memory tokenIds = new uint256[](tokenCounter);
      uint8 index = 0;
      for (uint256 i = _startTokenId(); i < _currentIndex; i++) {
        if (ownerOf(i) == _owner) {
          tokenIds[index] = i;
          index++;
        }
      }
      
      return tokenIds;
    }
  }

  /**
  * start the floor
  * @param _id id of NFT
  */
  function startFloor(uint256 _id) external {
    uint8 floor = attribute[_id].currentFloor;
    if (floor > LAST_FLOOR) return;

    require(msg.sender == ownerOf(_id), "Happy Robot NFT: You can start the floor for only your NFT.");
    require(!attribute[_id].locked, "Happy Robot NFT: You need to unlock the NFT first.");

    attribute[_id].secureVal = uint32(block.timestamp);
  }

  /**
  * update the floor information
  * @param _id id of NFT
  * @param _passTime total seconds that was taken the floor
  * @param _secureVal the secure value to prevent scammers that are tring to pass the floor without playing the gam
  */
  function passedFloor(uint256 _id, uint16 _passTime, uint256 _secureVal) external {
    uint8 floor = attribute[_id].currentFloor;
    if (floor > LAST_FLOOR) return;

    require(msg.sender == ownerOf(_id), "Happy Robot NFT: You can update the passing information for only your NFT.");
    require(!attribute[_id].locked, "Happy Robot NFT: You need to unlock the NFT first.");

    bool isScammer = attribute[_id].secureVal == 0;

    unchecked {
      if (!isScammer) {
        uint256 diffTime = 0;
        if (_secureVal > attribute[_id].secureVal)
          diffTime = _secureVal - attribute[_id].secureVal;
        else
          diffTime = attribute[_id].secureVal - _secureVal;

        if (startTimeErrLimit < diffTime)
          isScammer = true;
      }
    }

    require(!isScammer, "Happy Robot NFT: You didn't perform the floor exactly.");

    unchecked {
      attribute[_id].currentFloor = floor + 1;
      attribute[_id].totalTime += _passTime;
      attribute[_id].locked = true;
      attribute[_id].secureVal = 0;
    }

    // trigger passed floor event
    emit PassedFloor(_id, floor, _passTime, attribute[_id].totalTime);
  }

  /**
  * update the floor information
  * @param _owner owner of NFT
  * @param _id id of NFT
  */
  function unlockFloor(address _owner,  uint256 _id) public onlyOwner {
    require(_owner == ownerOf(_id), "Happy Robot NFT: You can unlock the floor for only your NFT.");
    attribute[_id].locked = false;
  }

  /**
    * mint a new NFT token 
    * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    * @param _owner address of the first owner of the token
    * @param _quantity quantity
    */
  function mint(
    address _owner,
    uint16 _quantity
  ) external onlyOwner {

    uint256 preIndex = _currentIndex;
    _safeMint(_owner, _quantity, "");

    // initialize attribute for NFT
    for (uint256 i = preIndex; i < _currentIndex; i++) {
      _resetAttribute(i);
    }
  }

  /**
  * claim neurons
  * @param _id id of NFT
  * @param _owner owner of token
  * @param _neurons the amount of neuron to claim
  * @return claimed neurons
  */
  function claimNeurons(address _owner, uint256 _id, uint32 _neurons) public onlyOwner returns(uint32) {
    require(_owner == ownerOf(_id), "You can claim neurons for only your NFT.");

    unchecked {
      uint32 curDayStamp = uint32(block.timestamp / DAYSTAMP_DIVIDE_VAL);
      uint32 neurons = curDayStamp - attribute[_id].neuronDayStamp;

      if (neurons < _neurons) {
        attribute[_id].neuronDayStamp = curDayStamp;
        return neurons;
      }

      attribute[_id].neuronDayStamp += _neurons;
    }

    return _neurons;
  }

  /**
  * get neurons of NFT
  * @param _id id of NFT
  * @return neurons
  */
  function getNeurons(uint256 _id) public view returns (uint32) {
    if (attribute[_id].neuronDayStamp == 0) {
      return 0;
    }

    unchecked {
      uint32 curDayStamp = uint32(block.timestamp / DAYSTAMP_DIVIDE_VAL);
      return curDayStamp - attribute[_id].neuronDayStamp;
    }
  }

  /**
  * get current floor of NFT
  * @param _id id of NFT
  * @return current floor of NFT
  */
  function getCurrentFloor(uint256 _id) public view returns (uint8) {
    return attribute[_id].currentFloor;
  }

  /**
  * get attribute of NFT
  * @param _id id of NFT
  * @return attribute of NFT
  */
  function getAttribute(uint256 _id) public view returns (Attribute memory) {
    Attribute memory attr = Attribute(uint16(_id), 
                                      attribute[_id].neuronDayStamp, 
                                      attribute[_id].currentFloor, 
                                      attribute[_id].totalTime, 
                                      attribute[_id].locked, 
                                      0);
    return attr;
  }

  /**
  * get attribute list of NFTs
  * @return attribute list of NFTs
  */
  function getTotalAttributes() public view returns (Attribute[] memory) {
    uint256 len = totalSupply();
    Attribute[] memory attrList = new Attribute[](len);

    for (uint256 i = 0; i < len; i++) {
      attrList[i] = attribute[i];
      attrList[i].secureVal = 0;
    }

    return attrList;
  }

  /**
  * get attribute list of NFTs
  * @param _owner the owner of token
  * @return attribute list of NFTs that the owner holds
  */
  function getAttributesForAccount(address _owner) public view returns (Attribute[] memory) {
    uint256[] memory idList = getTokenIdsOfOwner(_owner);

    Attribute[] memory attrList = new Attribute[](idList.length);

    for (uint256 i = 0; i < idList.length; i++) {
      attrList[i] = attribute[idList[i]];
      attrList[i].secureVal = 0;
    }

    return attrList;
  }

  /**
   * @notice Transfers token of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token
   */
  function transferFrom(
      address _from,
      address _to,
      uint256 _id
  ) public virtual override {
    ERC721A.transferFrom(_from, _to, _id);

    unchecked {
      // reset neuron value
      attribute[_id].neuronDayStamp = uint32(block.timestamp / DAYSTAMP_DIVIDE_VAL);
      attribute[_id].locked = true;
      attribute[_id].secureVal = 0;
    }
  }
  
  /**
   * @notice Transfers token of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token
   * @param _data    data of the token
   */
  function safeTransferFrom(
    address _from, 
    address _to, 
    uint256 _id,
    bytes memory _data
    ) public virtual override {
    
    ERC721A.safeTransferFrom(_from, _to, _id, _data);

    unchecked {
      // reset neuron value
      attribute[_id].neuronDayStamp = uint32(block.timestamp / DAYSTAMP_DIVIDE_VAL);
      attribute[_id].locked = true;
      attribute[_id].secureVal = 0;
    }
  }

  /**
   * burn token for token id
   * @param _tokenId    token id to burn
   */
  function burn(uint256 _tokenId) public onlyOwner {
    _burn(_tokenId);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title HappyRobotWhitelistToken
 * HappyRobotWhitelistToken - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract HappyRobotWhitelistToken is ERC1155, ERC1155Burnable, Ownable {
  using Counters for Counters.Counter;

  uint8  constant TOKEN_ID = 1;

  uint16 private tokenSupply = 0;

  // Contract name
  string public name;

  // Contract symbol
  string public symbol;

  uint8 constant SALE_STATUS_NONE = 0;
  uint8 saleStatus = SALE_STATUS_NONE;

  address[] private minters;
  mapping(address => uint8) mintsMap;
  mapping(address => uint8) burnsMap;

  uint16 private totalMints = 0;
  uint16 private totalBurns = 0;

  uint8 private maxPerWallet = 2;
  uint16 private maxWLTokens = 300;
  uint256 private mintFee = 0.075 ether;

  address payable constant public walletMaster = payable(0x6510711132d1c1c20BcA3Add36B8ad0fb6E73AFA);
  address payable constant public walletDevTeam = payable(0x52BD82C6B851AdAC6A77BC0F9520e5A062CD9a78);
  address payable constant public walletArtist = payable(0x22d57ccD4e05DD1592f52A4B0f909edBB82e8D26);

  event MintedWLToken(address _owner, uint16 _quantity, uint256 _totalOwned);

  constructor(
    string memory _uri
  ) ERC1155(_uri) {
    name = "HRF Token";
    symbol = "HRFTOKEN";
  }

  /**
  * Require msg.sender to be the master or dev team
  */
  modifier onlyMaster() {
    require(isMaster(msg.sender), "Happy Robot Whitelist Token: You are not a Master");
    _;
  }

  /**
  * require none sale status
  */
  modifier onlyNonSaleStatus() {
    require(saleStatus == SALE_STATUS_NONE, "Happy Robot Whitelist Token: It is sale period");
    _;
  }

  /**
  * get account is master or not
  * @param _account address
  * @return true or false
  */
  function isMaster(address _account) public pure returns (bool) {
    return walletMaster == payable(_account) || walletDevTeam == payable(_account);
  }

  /**
  * get token amount
  * @return token amount
  */
  function totalSupply() public view returns (uint16) {
    return tokenSupply;
  }

  /**
  * get uri
  * @return uri
  */
  function tokenUri() public view returns (string memory) {
    return ERC1155.uri(TOKEN_ID);
  }

  /**
  * set token uri
  * @param _uri token uri
  */
  function setURI(string memory _uri) public onlyOwner {      
    _setURI(_uri);
  }

  /**
  * get token quantity of account
  * @param _account account
  * @return token quantity of account
  */
  function quantityOf(address _account) public view returns (uint256) {
    return balanceOf(_account, TOKEN_ID);
  }

  /**
  * get max wl tokens per wallet
  * @return max wl tokens per wallet
  */
  function getMaxPerWallet() public view returns (uint8) {
    return maxPerWallet;
  }

  /**
  * set max wl tokens per wallet
  * @param _maxPerWallet max wl tokens per wallet
  */
  function setMaxPerWallet(uint8 _maxPerWallet) public onlyMaster {
    maxPerWallet = _maxPerWallet;
  }

  /**
  * get whitelist token mint fee
  * @return whitelist token mint fee
  */
  function getMintFee() public view returns (uint256) {
    return mintFee;
  }

  /**
  * set whitelist token mint fee
  * @param _mintFee mint fee
  */
  function setMintFee(uint256 _mintFee) public onlyMaster {
    mintFee = _mintFee;
  }

  /**
  * get sale status
  * @return sale status
  */
  function getSaleStatus() public view returns (uint8) {
    return saleStatus;
  }

  /**
  * set sale status
  * @param _saleStatus sale status
  */
  function setSaleStatus(uint8 _saleStatus) public onlyMaster {
    saleStatus = _saleStatus;
  }

  /**
  * get max wl tokens
  * @return max wl tokens
  */
  function getMaxWLTokens() public view returns (uint16) {
    return maxWLTokens;
  }

  /**
  * set max wl tokens
  * @param _maxWLTokens max wl tokens
  */
  function setMaxWLTokens(uint8 _maxWLTokens) public onlyMaster {
    maxWLTokens = _maxWLTokens;
  }

  /**
  * get whitelist token minters
  */
  function getMinters() public view returns (address[] memory) {
    return minters;
  }

  /**
  * check if _account is in the whitelist token minters
  * @param _account address
  * @return 
  */
  function existInMinters(address _account) public view returns (bool) {
    for (uint256 i = 0; i < minters.length; i++) {
      if (minters[i] == _account)
        return true;
    }
    return false;
  }

  /**
  * add an address into the whitelist
  * @param _account address
  */
  function addToMinters(address _account) internal {
    // if already registered, skip
    for (uint16 i = 0; i < minters.length; i++) {
      if (minters[i] == _account)   return;
    }

    // add address to the list
    minters.push(_account);
  }

  /**
  * remove an address from the minter list
  * @param _account address
  */
  function removeFromMinters(address _account) internal {
    // find index of _from
    uint256 index = 0xFFFF;
    uint256 len = minters.length;
    for (uint256 i = 0; i < len; i++) {
        if (minters[i] == _account) {
            index = i;
            break;
        }
    }

    // remove it
    if (index != 0xFFFF && len > 0) {
        minters[index] = minters[len - 1];
        minters.pop();
    }
  }

  /**
  * get number of total minted whitelist tokens
  * @return number of total minted whitelist tokens
  */
  function getTotalMinted() public view returns (uint16) {
    return totalMints;
  }

  /**
  * get number of total burned whitelist tokens
  * @return number of total burned whitelist tokens
  */
  function getTotalBurned() public view returns (uint16) {
    return totalBurns;
  }

  /**
  * get number of minted count for account
  * @param _account address
  * @return number of minted count for account
  */
  function getMints(address _account) public view returns (uint8) {
    return mintsMap[_account];
  }

  /**
  * get number of burned count for account
  * @param _account address
  * @return number of burned count for account
  */
  function getBurns(address _account) public view returns (uint8) {
    return burnsMap[_account];
  }

  /**
  * get number of owned whitelist token(including burned count) for account
  * @param _account address
  * @return number of owned whitelist token(including burned count) for account
  */
  function getOwned(address _account) public view returns (uint8) {
    unchecked {
      return uint8(quantityOf(_account)) + burnsMap[_account];
    }
  }

  /**
  * import old minters' data
  * @param _oldMinters minters' address list
  * @param _quantities minters' quantity list
  */
  function importMintedAddress(address[] calldata _oldMinters, uint8[] calldata _quantities) external onlyMaster {
    require(_oldMinters.length == _quantities.length, "Happy Robot Whitelist Token: The length of two array must be the same.");
    for (uint16 i = 0; i < _oldMinters.length; i++) {
      if (_quantities[i] == 0) continue;
      
      addToMinters(_oldMinters[i]);

      unchecked {
        totalMints += _quantities[i];
        mintsMap[_oldMinters[i]] += _quantities[i]; // add mints map
        tokenSupply += _quantities[i];
      }
    }
  }

  /**
  * import old owners' data
  * @param _oldOwners owners' address list
  * @param _quantities owners' quantity list
  */
  function importOwnedAddress(address[] calldata _oldOwners, uint8[] calldata _quantities) external onlyMaster {
    require(_oldOwners.length == _quantities.length, "Happy Robot Whitelist Token: The length of two array must be the same.");
    for (uint16 i = 0; i < _oldOwners.length; i++) {
      if (_quantities[i] == 0)  continue;

      _mint(_oldOwners[i], TOKEN_ID, _quantities[i], '');
    }
  }

  /**
  * check if mint is possible for account
  * @param _account account
  * @param _quantity quantity
  * @return true or false
  */
  function canMintForAccount(address _account, uint16 _quantity) internal view returns (bool) {
    if (isMaster(_account)) return true;
    
    unchecked {
      uint8 balance = uint8(quantityOf(_account));
      uint8 totalOwned = balance + burnsMap[_account];

      return totalOwned + _quantity - 1 < maxPerWallet;
    }
  }

  /**
  * mint whitelist token
  * @param _quantity token amount
  */
  function mint(uint8 _quantity) external payable onlyNonSaleStatus {

    require(canMintForAccount(msg.sender, _quantity) == true, "Happy Robot Whitelist Token: Maximum whitelist token mint  already reached for the account");
    require(totalSupply() + _quantity - 1 < maxWLTokens, "Happy Robot Whitelist Token: Maximum whitelist token already reached");
    
    if (!isMaster(msg.sender)) {
        require(msg.value > mintFee * _quantity - 1, "Happy Robot Whitelist Token: Not enough ETH sent");

        // perform mint
        mint(msg.sender, _quantity);

        unchecked {
            uint256 fee = mintFee * _quantity;

            uint256 feeForDev = (uint256)(fee / 200); // 0.5% to the dev
            walletDevTeam.transfer(feeForDev);

            uint256 feeForArtist = (uint256)(fee / 40); // 2.5% to the dev
            walletArtist.transfer(feeForArtist);

            // return back remain value
            uint256 remainVal = msg.value - fee;
            address payable caller = payable(msg.sender);
            caller.transfer(remainVal);
        }

    } else {   // no price for master wallet
        // perform mint
        mint(msg.sender, _quantity);

        // return back the ethers
        address payable caller = payable(msg.sender);
        caller.transfer(msg.value);
    }
  }

  /**
  * mint tokens
  * @param _to address to mint
  * @param _quantity token quantity
  */
  function mint(address _to, uint8 _quantity) internal {
    _mint(_to, TOKEN_ID, _quantity, '');
    addToMinters(_to);

    unchecked {
      totalMints += _quantity;
      mintsMap[_to] += _quantity; // add mints map
      tokenSupply += _quantity;
    }

    // trigger whitelist token minted event
    emit MintedWLToken(_to, _quantity, totalMints);
  }

  /**
  * burn token
  * @param _from address to burn
  * @param _quantity token quantity
  */
  function burn(address _from, uint8 _quantity) public onlyOwner {
    _burn(_from, TOKEN_ID, _quantity);

    unchecked {
      totalBurns += _quantity;
      burnsMap[_from] += _quantity; // add burns map
      tokenSupply -= _quantity;
    }
  }

  /**
  * withdraw balance to only master wallet
  */
  function withdrawAll() external onlyMaster {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}