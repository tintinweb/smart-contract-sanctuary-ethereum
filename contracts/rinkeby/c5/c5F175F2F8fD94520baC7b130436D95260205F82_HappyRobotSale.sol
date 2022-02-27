// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

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
    uint8 private maxWLTokenPerWallet = 2;
    uint16 private maxWLTokens = 300;

    address private nftAddress;
    address private wlTokenAddress;

    uint256 private nftMintFee = 0.2 ether;
    uint256 private wlTokenMintFee = 0.15 ether;

    uint8 private genIndex = GEN1_INDEX;
    uint8 private saleStatus = SALE_STATUS_NONE;

    uint8 private isProduct = 0;     // false means for testing

    address[] private whitelist;
    address[] private wlTokenMinters;
    address[] private giftWhitelist;
    mapping(address => uint32) neuronsMap;

    mapping(address => uint16) wlTokenMintsMap;
    mapping(address => mapping(uint8 => uint16)) nftExchangeMap;
    mapping(address => mapping(uint8 => uint16)) nftMintsMap;

    mapping(uint8 => uint16) totalExchangedNFTs;
    mapping(uint8 => uint16) totalMintedNFTs;

    address payable constant public walletMaster = payable(0x6510711132d1c1c20BcA3Add36B8ad0fb6E73AFA);
    address payable constant public walletDevTeam = payable(0x52BD82C6B851AdAC6A77BC0F9520e5A062CD9a78); 

    event ChangedSaleStatus(uint8 _genIndex, uint8 _saleStatus);
    event MintedNFT(address _owner, uint16 _quantity, uint256 _totalNFT);
    event ExchangedNFT(address _owner, uint16 _quantity, uint256 _totalNFT, uint256 _totalWhitelistToken);
    event MintedWLToken(address _owner, uint16 _quantity, uint256 _totalWhitelistToken);

    /**
    * Require msg.sender to be the master or dev team
    */
    modifier onlyMaster() {
        require(isMaster(msg.sender), "Happy Robot: You are not a Master");
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
    * require not product
    */
    modifier onlyTesting() {
        require(isProduct == 0, "Happy Robot: It is Product mode not Testing mode");
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

    constructor(address _nftAddress, address _wlTokenAddress, uint8 _isProduct, uint8 _saleStatus) {
        nftAddress = _nftAddress;
        wlTokenAddress = _wlTokenAddress;
        isProduct = _isProduct;
        saleStatus = _saleStatus;
    }

    /**
    * set contract as product not testing
    */
    function setProduct() public onlyMaster {
        isProduct = 1;
    }

    /**
    * get if current is product mode
    */
    function isProductMode() public view returns (bool) {
        return (isProduct == 1);
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
    function isMaster(address _account) public pure returns (bool) {
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
    * get max wl tokens per wallet
    * @return max wl tokens per wallet
    */
    function getMaxWLTokenPerWallet() public view returns (uint8) {
        return maxWLTokenPerWallet;
    }

    /**
    * set max wl tokens per wallet
    * @param _maxWLTokenPerWallet max wl tokens per wallet
    */
    function setMaxWLTokenPerWallet(uint8 _maxWLTokenPerWallet) public {
        maxWLTokenPerWallet = _maxWLTokenPerWallet;
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
    function setMaxWLTokens(uint8 _maxWLTokens) public {
        maxWLTokens = _maxWLTokens;
    }

    /**
    * get generation index
    * @return 1: generation1, 2: generation2
    */
    function getGenerationIndex() public view returns (uint8) {
        return genIndex;
    }

    /**
    * get sale status
    * @return 0: pre sale, 1: public sale
    */
    function getSaleStatus() public view returns (uint8) {
        return saleStatus;
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
    * get number of total minted whitelist tokens
    * @return number of total minted whitelist tokens
    */
    function getTotalMintedWLTokens() public view returns (uint16) {
        unchecked {
            return HappyRobotWhitelistToken(wlTokenAddress).totalSupply() + totalExchangedNFTs[GEN1_INDEX] + totalExchangedNFTs[GEN2_INDEX];
        }
    }

    /**
    * get number of total exchanged nfts for generation index
    * @param _genIndex generation index
    * @return number of total exchanged nfts for generation index
    */
    function getTotalExchangedNFTs(uint8 _genIndex) public view returns (uint16) {
        return totalExchangedNFTs[_genIndex];
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
    * get number of minted wl token for account
    * @param _account address
    * @return number of minted wl token for account
    */
    function getWLTokenMints(address _account) public view returns (uint16) {
        return wlTokenMintsMap[_account];
    }

    /**
    * get number of exchanged nfts for account and generation
    * @param _account address
    * @param _genIndex generation index
    * @return number of exchanged nfts for account and generation
    */
    function getExchangedNFTs(address _account, uint8 _genIndex) public view returns (uint16) {
        return nftExchangeMap[_account][_genIndex];
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
    * get number of owned whitelist token(including exchanged NFT count) for account
    * @param _account address
    * @return number of owned whitelist token(including exchanged NFT count) for account
    */
    function getWLTokenOwned(address _account) public view returns (uint16) {
        unchecked {
            uint16 wlTokenBalance = uint16(HappyRobotWhitelistToken(wlTokenAddress).balanceOf(_account));
            return wlTokenBalance + nftExchangeMap[_account][GEN1_INDEX] + nftExchangeMap[_account][GEN2_INDEX];
        }
    }

    /**
    * update the floor information
    * @param _id id of NFT
    */
    function unlockFloor(uint256 _id) public {
        HappyRobotNFT nft = HappyRobotNFT(nftAddress);

        uint8 currentFloor = nft.getCurrentFloor(_id);

        // to unlock the next floor
        uint8 reqNeurons = firstLevelNeurons;
        if (currentFloor > MIDDLE_FLOOR) 
            reqNeurons = secondLevelNeurons;

        uint32 availableNeurons = neuronsMap[msg.sender] + nft.getNeurons(_id);

        require(availableNeurons >= reqNeurons, "Happy Robot: Your neurons are not enough to unlock next level");

        uint16 claimedNeurons = nft.claimNeurons(msg.sender, _id, reqNeurons);
        
        unchecked {
            if (claimedNeurons < reqNeurons)
                neuronsMap[msg.sender] -= (reqNeurons - claimedNeurons);
        }
        
        nft.unlockFloor(msg.sender, _id);
    }

    /**
    * claim neurons
    * @param _id id of NFT
    */
    function claimNeurons(uint256 _id) public returns (uint32) {
        HappyRobotNFT nft = HappyRobotNFT(nftAddress);
        uint16 neurons = nft.getNeurons(_id);
        uint16 claimedNeurons = nft.claimNeurons(msg.sender, _id, neurons);

        unchecked {
            neuronsMap[msg.sender] += claimedNeurons;
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
    * get whitelist token minters
    */
    function getWLTokenMinters() public view returns (address[] memory) {
        return wlTokenMinters;
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
    * check if _account is in the whitelist token minters
    * @param _account address
    * @return 
    */
    function existInWLTokenMinters(address _account) public view returns (bool) {
        for (uint256 i = 0; i < wlTokenMinters.length; i++) {
            if (wlTokenMinters[i] == _account)
                return true;
        }
        return false;
    }

    /**
    * add an address into the whitelist
    * @param _account address
    */
    function addToWLTokenMinters(address _account) internal {        
        // if already registered, skip
        for (uint16 i = 0; i < wlTokenMinters.length; i++) {
            if (wlTokenMinters[i] == _account)   return;
        }

        // add address to the list
        wlTokenMinters.push(_account);
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
    * get whitelist token mint fee
    * @return whitelist token mint fee
    */
    function getWLTokenMintFee() public view returns (uint256) {
        return wlTokenMintFee;
    }

    /**
    * set whitelist token mint fee
    * @param _wlTokenMintFee mint fee
    */
    function setWLTokenMintFee(uint256 _wlTokenMintFee) public onlyMaster {
        wlTokenMintFee = _wlTokenMintFee;
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
            uint16 balance = uint16(HappyRobotNFT(nftAddress).balanceOf(_account)) + _quantity;
            if (uint8(balance) <= maxNFTPerWallet)
                retValue = true;
        }
        return retValue;
    }

    /**
    * check if mint is possible for account
    * @param _account account
    * @param _quantity quantity
    * @return true or false
    */
    function canMintWLTokenForAccount(address _account, uint16 _quantity) internal view returns (bool) {
        if (isMaster(_account)) return true;
        
        unchecked {
            uint8 balance = uint8(HappyRobotWhitelistToken(wlTokenAddress).balanceOf(_account));
            uint8 totalOwned = balance + uint8(nftExchangeMap[_account][GEN1_INDEX] + nftExchangeMap[_account][GEN2_INDEX]);

            return totalOwned + _quantity <= maxWLTokenPerWallet;
        }
    }

    /**
    * mint a new NFT 
    * @param _quantity token quantity
    */
    function mintNFT(uint16 _quantity) external payable onlySaleStatus {

        require(canMintNFTForGeneration(genIndex, _quantity), "Happy Robot: Maximum NFT mint already reached for the generation");

        require(canMintNFTForAccount(msg.sender, _quantity), "Happy Robot: Maximum NFT mint already reached for the account");

        HappyRobotWhitelistToken whitelistToken = HappyRobotWhitelistToken(wlTokenAddress);
        bool hasWhitelistToken = whitelistToken.balanceOf(msg.sender) > 0;

        if (saleStatus == SALE_STATUS_PRE && !hasGift(msg.sender) && !isMaster(msg.sender)) {
            require(hasWhitelistToken || existInWLTokenMinters(msg.sender) || existInWhitelist(msg.sender), "Happy Robot: You should be in the whitelist or you should have a whitelist token");
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
    function exchangeNFTWithWhitelistToken(uint16 _quantity) external onlySaleStatus {

        HappyRobotWhitelistToken whitelistToken = HappyRobotWhitelistToken(wlTokenAddress);
        require(whitelistToken.balanceOf(msg.sender) >= _quantity, "Happy Robot: Not enough HRF tokens to exchange");

        HappyRobotNFT nft = HappyRobotNFT(nftAddress);

        if (nft.isGen1SoldOut()) {
            require(canMintNFTForGeneration(GEN2_INDEX, _quantity), "Happy Robot: Maximum NFT mint already reached for the generation 2");
        }

        require(canMintNFTForAccount(msg.sender, _quantity), "Happy Robot: Maximum NFT mint already reached for the account");

        // perform mint
        nft.mint(msg.sender, _quantity);

        // burn whitelist token
        whitelistToken.burn(msg.sender, _quantity);

        unchecked {
            totalExchangedNFTs[genIndex] += _quantity;
            nftExchangeMap[msg.sender][genIndex] += _quantity;
        }

        // trigger nft token minted event
        emit ExchangedNFT(msg.sender, _quantity, nft.totalSupply(), getTotalMintedWLTokens());
    }

    /**
    * mint whitelist token
    * @param _quantity token amount
    */
    function mintWLToken(uint16 _quantity) external payable onlyNonSaleStatus {

        HappyRobotWhitelistToken token = HappyRobotWhitelistToken(wlTokenAddress);

        require(canMintWLTokenForAccount(msg.sender, _quantity) == true, "Happy Robot: Maximum whitelist token mint  already reached for the account");
        require(token.totalSupply() + _quantity <= maxWLTokens, "Happy Robot: Maximum whitelist token already reached");
        
        if (!isMaster(msg.sender)) {
            require(msg.value >= wlTokenMintFee * _quantity, "Happy Robot: Not enough ETH sent");

            // perform mint
            token.mint(msg.sender, _quantity);

            unchecked {
                uint256 mintFee = wlTokenMintFee * _quantity;

                uint256 feeForDev = (uint256)(mintFee / 200); // 0.5% to the dev
                walletDevTeam.transfer(feeForDev);

                // return back remain value
                uint256 remainVal = msg.value - mintFee;
                address payable caller = payable(msg.sender);
                caller.transfer(remainVal);
            }

        } else {   // no price for master wallet
            // perform mint
            token.mint(msg.sender, _quantity);

            // return back the ethers
            address payable caller = payable(msg.sender);
            caller.transfer(msg.value);
        }

        addToWLTokenMinters(msg.sender);
        unchecked {
            wlTokenMintsMap[msg.sender] += _quantity;
        }

        // trigger whitelist token minted event
        emit MintedWLToken(msg.sender, _quantity, getTotalMintedWLTokens());
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

    /**
    * reset whitelist tokens and NFTs of wallet address
    */
    function reset() external onlyTesting onlyNotMaster {
        HappyRobotWhitelistToken wlToken = HappyRobotWhitelistToken(wlTokenAddress);
        uint256 wlTokenMints = wlTokenMintsMap[msg.sender];

        uint256 nftMints = 0;
        unchecked {
            nftMints = nftMintsMap[msg.sender][GEN1_INDEX] + nftMintsMap[msg.sender][GEN2_INDEX];
        }

        HappyRobotNFT nft = HappyRobotNFT(nftAddress);

        // reset maps
        wlTokenMintsMap[msg.sender] = 0;

        unchecked {
            totalExchangedNFTs[GEN1_INDEX] -= nftExchangeMap[msg.sender][GEN1_INDEX];
            totalExchangedNFTs[GEN2_INDEX] -= nftExchangeMap[msg.sender][GEN2_INDEX];
        }
        nftExchangeMap[msg.sender][GEN1_INDEX] = 0;
        nftExchangeMap[msg.sender][GEN2_INDEX] = 0;

        unchecked {
            totalMintedNFTs[GEN1_INDEX] -= nftMintsMap[msg.sender][GEN1_INDEX];
            totalMintedNFTs[GEN2_INDEX] -= nftMintsMap[msg.sender][GEN2_INDEX];
        }
        nftMintsMap[msg.sender][GEN1_INDEX] = 0;
        nftMintsMap[msg.sender][GEN2_INDEX] = 0;

        // reset neurons
        neuronsMap[msg.sender] = 0;

        // burn wl tokens
        uint256 wlTokenBalance = wlToken.balanceOf(msg.sender);
        if (wlTokenBalance > 0) {
            wlToken.burn(msg.sender, uint16(wlTokenBalance));
        }

        // burn nft tokens
        uint256[] memory nftIds = nft.getTokenIdsOfOwner(msg.sender);
        for (uint16 i = 0; i < nftIds.length; i++) {
            nft.safeTransferFrom(msg.sender, walletMaster, nftIds[i], "");
        }

        // uint256 txFees = 0;
        // unchecked {
        //     txFees = wlTokenMints * wlTokenMintFee + nftMints * nftMintFee;
        // }

        // if (txFees == 0)    return;

        // // send transaction fees
        // address payable to = payable(msg.sender);

        // if (txFees > address(this).balance) 
        //     txFees = address(this).balance;

        // to.transfer(txFees);
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

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import './ERC721A.sol';
import './Utils.sol';

/**
 * @title HappyRobotNFT
 * HappyRobotNFT - ERC721 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract HappyRobotNFT is ERC721A, Ownable {

  // max sizes for every generation
  uint16 public constant gen1MaxQuantity = 3333;
  uint16 public constant gen2MaxQuantity = 3334;
  
  uint8 constant startTimeErrLimit = 60;
  
  // constant value for every generation
  uint8 public constant GEN1_INDEX = 1;
  uint8 public constant GEN2_INDEX = 2;

  uint8 constant LAST_FLOOR = 10;
  
  // happy robot nft attributes
  struct Attribute {
    uint16  neuronDayStamp; // day value of timestamp = timestamp / (24 * 60 * 60),
                            // when minting NFT, this value is set with the day value of current timestamp
    uint8   currentFloor;   // current floor value: from 1 to 10
    uint24  totalTime;      // total seconds which the nft passed floors
    bool    locked;         // the flag if the floor is locked or unlocked
    uint32  floorStartTime; // the time that the nft start the floor
  }

  address proxyRegistryAddress;

  mapping(uint256 => Attribute) private attribute; // attribute of happy robot nft
  
  // base uri
  string private baseURI;

  event PassedFloor(uint256 _id, uint8 _floor, uint16 _passTime, uint24 _totalPassTime);

  constructor(address _proxyRegistryAddress) ERC721A("Happy Robot", "HAPPYROBOT") {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
   * Will update the base URL of token's URI
   * @param _newBaseURI New base URL of token's URI
   */
  function setBaseURI(
    string memory _newBaseURI
  ) public onlyOwner {
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
      uint16 neuronDayStamp = uint16(block.timestamp / (24 * 60 * 60));
      Attribute memory attr = Attribute(neuronDayStamp, 1, 0, false, 0);

      attribute[_id] = attr;
    }
  }

  /**
  * get token id list of owner
  * @param _owner the owner of token
  * @return token id list
  */
  function getTokenIdsOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 numMintedSoFar = totalSupply();
    address currOwnershipAddr;

    // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
    uint8 tokenCounter = 0;

    unchecked {
      // get counter of tokens
      for (uint256 i; i < numMintedSoFar; i++) {
        TokenOwnership memory ownership = _ownerships[i];
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == _owner) {
          tokenCounter++;
        }
      }

      // configure token id list
      uint256[] memory tokenIds = new uint256[](tokenCounter);
      uint8 index = 0;
      for (uint256 i; i < numMintedSoFar; i++) {
        TokenOwnership memory ownership = _ownerships[i];
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == _owner) {
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

    attribute[_id].floorStartTime = uint32(block.timestamp);
  }

  /**
  * update the floor information
  * @param _id id of NFT
  * @param _passTime total seconds that was taken the floor
  */
  function passedFloor(uint256 _id, uint16 _passTime) external {
    uint8 floor = attribute[_id].currentFloor;
    if (floor > LAST_FLOOR) return;

    require(msg.sender == ownerOf(_id), "Happy Robot NFT: You can update the passing information for only your NFT.");
    require(!attribute[_id].locked, "Happy Robot NFT: You need to unlock the NFT first.");

    bool isScammer = attribute[_id].floorStartTime == 0;

    if (!isScammer) {
      uint256 diffTime = 0;
      if (block.timestamp >= attribute[_id].floorStartTime + _passTime)
        diffTime = block.timestamp - (attribute[_id].floorStartTime + _passTime);
      else
        diffTime = (attribute[_id].floorStartTime + _passTime) - block.timestamp;

      if (startTimeErrLimit < diffTime)
        isScammer = true;
    }

    require(!isScammer, "Happy Robot NFT: You didn't perform the floor exactly.");

    unchecked {
      attribute[_id].currentFloor = floor + 1;
      attribute[_id].totalTime += _passTime;
      attribute[_id].locked = true;
      attribute[_id].floorStartTime = 0;
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

    uint256 preIndex = currentIndex;
    _safeMint(_owner, _quantity, "");

    // initialize attribute for NFT
    for (uint256 i = preIndex; i < currentIndex; i++) {
      _resetAttribute(i);
    }
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC721A.isApprovedForAll(_owner, _operator);
  }

  /**
  * claim neurons
  * @param _id id of NFT
  * @param _owner owner of token
  * @param _neurons the amount of neuron to claim
  * @return claimed neurons
  */
  function claimNeurons(address _owner, uint256 _id, uint16 _neurons) public onlyOwner returns(uint16) {
    require(_owner == ownerOf(_id), "You can claim neurons for only your NFT.");

    unchecked {
      uint16 curDayStamp = uint16(block.timestamp / (24 * 60 * 60));
      uint16 neurons = curDayStamp - attribute[_id].neuronDayStamp;

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
  function getNeurons(uint256 _id) public view returns (uint16) {
    unchecked {
      uint16 curDayStamp = uint16(block.timestamp / (24 * 60 * 60));
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
    Attribute memory attr = Attribute(attribute[_id].neuronDayStamp, attribute[_id].currentFloor, attribute[_id].totalTime, attribute[_id].locked, attribute[_id].floorStartTime);
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
      attribute[_id].neuronDayStamp = uint16(block.timestamp / (24 * 60 * 60));
      attribute[_id].locked = false;
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
      attribute[_id].neuronDayStamp = uint16(block.timestamp / (24 * 60 * 60));
      attribute[_id].locked = false;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import './Utils.sol';

/**
 * @title HappyRobotWhitelistToken
 * HappyRobotWhitelistToken - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract HappyRobotWhitelistToken is ERC1155, Ownable {
  using Counters for Counters.Counter;

  uint8  constant TOKEN_ID = 1;

  uint16 private tokenSupply = 0;

  // Contract name
  string public name;

  // Contract symbol
  string public symbol;

  address proxyRegistryAddress;

  constructor(
    string memory _uri, address _proxyRegistryAddress
  ) ERC1155(_uri) {
    name = "HRF Token";
    symbol = "HRFTOKEN";

    proxyRegistryAddress = _proxyRegistryAddress;
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
  function uri() public view returns (string memory) {
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
  * get token balance of account
  * @param _account account
  * @return token balance of account
  */
  function balanceOf(address _account) public view returns (uint256) {
    return balanceOf(_account, TOKEN_ID);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
  * mint tokens
  * @param _to address to mint
  * @param _quantity token quantity
  */
  function mint(address _to, uint16 _quantity) public onlyOwner {
    _mint(_to, TOKEN_ID, _quantity, '');
    unchecked {
      tokenSupply += _quantity;
    }
  }

  /**
  * burn token
  * @param _from address to burn
  * @param _quantity token quantity
  */
  function burn(address _from, uint16 _quantity) public onlyOwner {
    _burn(_from, TOKEN_ID, 1);
    unchecked {
      tokenSupply -= _quantity;
    }
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

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 - 1 (max value of uint128) of supply
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex;

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
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), 'ERC721A: global index out of bounds');
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), 'ERC721A: owner index out of bounds');
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        revert('ERC721A: unable to get token of owner by index');
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721A: balance query for the zero address');
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(owner != address(0), 'ERC721A: number minted query for the zero address');
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), 'ERC721A: owner query for nonexistent token');

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert('ERC721A: unable to determine the owner of token');
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
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

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
        require(to != owner, 'ERC721A: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721A: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'ERC721A: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), 'ERC721A: approve to caller');

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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721A: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
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
        uint256 startTokenId = currentIndex;
        require(to != address(0), 'ERC721A: mint to the zero address');
        require(quantity != 0, 'ERC721A: quantity must be greater than 0');

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe) {
                    require(
                        _checkOnERC721Received(address(0), to, updatedIndex, _data),
                        'ERC721A: transfer to non ERC721Receiver implementer'
                    );
                }

                updatedIndex++;
            }

            currentIndex = updatedIndex;
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
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(isApprovedOrOwner, 'ERC721A: transfer caller is not owner nor approved');

        require(prevOwnership.addr == from, 'ERC721A: transfer from incorrect owner');
        require(to != address(0), 'ERC721A: transfer to the zero address');

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
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721A: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
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
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
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
pragma solidity ^0.8.1;

contract OwnableDelegateProxy { }

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
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