// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NFTPussies.sol";
import "./IPrices.sol";

library MysteryBox {
    uint16 public constant RARITY_COUNT = 4;

    struct Collection {
        uint16[][4] rarities;
        uint256 cap;
        uint256 minted;
        uint256 price;
        uint256 revealTime;
        uint256 mintTime;
        uint16 maxBuy;
        bool mintable;
        bool initialized;
        bool bnbBuying;
    }

    /**
    * @dev The Graph does not support nested arrays, so we need to split rarities 
    * to separate array for communication outside of chain
    */
    struct CollectionPublic {
        uint16[] common;
        uint16[] rare;
        uint16[] legendary;
        uint16[] puss;
        uint256 cap;
        uint256 minted;
        uint256 price;
        uint256 revealTime;
        uint256 mintTime;
        uint16 maxBuy;
        bool mintable;
        bool initialized;
        bool bnbBuying;
    }

    /**
    * @notice Set collection state (mintability)
    * @param c collection
    * @param state desired state
    */
    function setState(Collection storage c, bool state) internal {
        c.mintable = state;
    }

    /**
    * @notice Set whether the collection is buyable with BNB 
    * @param c collection
    * @param state desired state
    */
    function setBnbBuying(Collection storage c, bool state) internal {
        c.bnbBuying = state;
    }

    /**
    * @notice Get whether the colleaction can be revealed
    * @param c collection
    * @return bool true if the collection is revealable
    */
    function revealable(Collection storage c) internal view returns(bool) {
        return block.timestamp >= c.revealTime;
    }

    /**
    * @notice Check whether the collection is mintable
    * @param c collection
    * @return bool true if the collection is mintable
    */
    function isOpen(Collection storage c) internal view returns(bool) {
        return c.mintable && c.mintTime <= block.timestamp;
    }

    /**
    * @notice Check whether the the minted amount will surpass cap or not
    * @param c collection
    * @param amount amount to be minted
    * @return bool true if the provided amount will not surpass cap
    */
    function belowCap(Collection storage c, uint256 amount) internal view returns(bool) {
        return c.cap >= c.minted + amount;
    }

    /**
    * @notice Get max cap for the collection
    * @param rarities array containing number of NFTs per rarity and photo
    * @return cap max cap for collection
    */
    function getCap(uint16[][4] memory rarities) internal pure returns(uint32 cap) {
        for(uint16 i=0; i<RARITY_COUNT; i++) {
            for(uint16 j=0; j<rarities[i].length; j++) {
                cap +=rarities[i][j];
            }
        }
    }

    /**
    * @notice Gets how many copies of a photo is available
    * @param c collection
    * @param photo photo id
    * @return copies number of copies */
    function getCopies(Collection storage c, uint16 photo) internal view returns(uint16 copies) {
        for(uint16 i=0; i<RARITY_COUNT; i++) {
            copies += c.rarities[i][photo];
        }
    }



}

contract NFTPMysteryBox is ERC1155, ReentrancyGuard, Ownable {
    using MysteryBox for MysteryBox.Collection;

    uint256 private constant GAS_BUFFER = 100_000;
    string public constant name = "NFT Pussies Mystery Box";
    string public constant symbol = "NFTPMB";
    uint256 public maxReveal = 25;

    string private _contractMetadataURI;

    uint256 public requestCounterStart = 1;
    uint256 public requestCounterEnd = 1;

    MysteryBox.Collection[] private collections;
    mapping(uint256 => mapping(uint16 => mapping(uint16 => uint16))) private collectionPhotoRarityMinted;
    mapping(uint256 => uint256) sale;
    mapping(uint256 => RevealRequestInfo) public revealRequests;
    mapping(address => uint256) public revealRequested;

    address public admin;
    address public receiverOfEarnings;
    IPussiesNFT public nftp;
    IERC20 public paidWith;
    IPrices public prices;
    address public stablecoin;

    event Reveal(uint256 collectionId, uint256[] nftIds, uint16[] rarities, uint16[] photos, address owner, uint256 counter);
    event RevealRequest(address owner, uint256 collectionId, uint256 amount, uint256 nonceOffset, uint256 timestamp);
    event RevealFailed(address account, uint256 collectionId, uint256 amount, uint256 nonce);
    event Collection(uint256 id, uint256 revealTime, uint256 mintTime);
    event CollectionUpdated(uint256 id, uint256 revealTime, uint256 mintTime);
    event StateSet(uint256 id, bool state);
    event BnbBuyingSet(uint256 id, bool state);
    event BoxMint(uint256 id, uint256 amount, uint256 cost, address owner, bool bnb);

    struct RevealRequestInfo {
        address account;
        uint256 amount;
        uint256 collectionId;
        uint256 nonce;
    }

    struct RarityPhoto {
        uint16 rarity;
        uint16 photo;
        uint16 raritySum;
        uint16 rarityGroup;
    }

    constructor(
        string memory uri_,
        string memory contractMetadataURI,
        address nftp_,
        address token,
        address prices_,
        address stablecoin_,
        address admin_
    ) ERC1155(uri_) {
        require(nftp_ != address(0), "NFT address cannot be 0");
        require(token != address(0), "Token address cannot be 0");
        require(prices_ != address(0), "Prices address cannot be 0");
        require(admin_ != address(0), "Admin address cannot be 0");
        nftp = IPussiesNFT(nftp_);
        paidWith = IERC20(token);
        prices = IPrices(prices_);
        _contractMetadataURI = contractMetadataURI;
        receiverOfEarnings = owner();
        stablecoin = stablecoin_;
        admin = admin_;
    }

    //====================== ONLY OWNER ==============================

    /**
    * @notice Adds new collection
    * @param common Array with numbers of photos for common rarity
    * @param rare Array with numbers of photos for rare rarity
    * @param legendary Array with numbers of photos for legendary rarity
    * @param puss Array with numbers of photos for puss rarity
    * @param price Price per MysteryBox
    * @param revealTime Time when the box reveal (i.e. final NFT mint) starts
    * @param mintTime Time when the box mint starts
    */
    function addCollection(
        uint16[] memory common,
        uint16[] memory rare,
        uint16[] memory legendary,
        uint16[] memory puss,
        uint256 price,
        uint256 revealTime,
        uint256 mintTime,
        uint16 maxBuy
    ) external onlyOwner {
        require(common.length == rare.length && rare.length == legendary.length && legendary.length == puss.length, "Array lenght mismatch");
        

        uint256 cap = MysteryBox.getCap(uint16[][4]([
                    common,
                    rare,
                    legendary,
                    puss
                ]));

        collections.push(
            MysteryBox.Collection(
                [
                    common,
                    rare,
                    legendary,
                    puss
                ],
                cap,
                0,
                price,
                revealTime,
                mintTime,
                maxBuy,
                true,
                true,
                false
            )
        );

        emit Collection(collections.length-1, revealTime, mintTime);
    }

    function updateCollection(
        uint256 id,
        uint16[] memory common,
        uint16[] memory rare,
        uint16[] memory legendary,
        uint16[] memory puss,
        uint256 price,
        uint256 revealTime,
        uint256 mintTime,
        uint16 maxBuy,
        bool bnbBuying
    ) external onlyOwner {
        MysteryBox.Collection storage c = collections[id];
        require(c.initialized, "Collection does not exists");
        require(common.length == rare.length && rare.length == legendary.length && legendary.length == puss.length, "Array lenght mismatch");

        uint16[] memory commonM;
        uint16[] memory rareM;
        uint16[] memory legendaryM;
        uint16[] memory pussM;

        (commonM, rareM, legendaryM, pussM) = getCollectionMinted(id);
        
        for(uint256 i=0; i<common.length; i++) {
            require(common[i] >= commonM[i] && rare[i] >= rareM[i] && legendary[i] >= legendaryM[i] && puss[i] >= pussM[i], "New photo count lower than minted");
        }

        c.rarities = [common, rare, legendary, puss];
        c.price = price;
        c.revealTime = revealTime;
        c.mintTime = mintTime;
        c.bnbBuying = bnbBuying;
        c.maxBuy = maxBuy;

        emit CollectionUpdated(id, revealTime, mintTime);

    }

    /**
    * @notice Sets collection state to mintable/closed
    * @param id collection id
    * @param state true if collection should be mintable, false otherwise
    */
    function setState(uint256 id, bool state) external onlyOwner {
        MysteryBox.Collection storage c = collections[id];
        c.setState(state);

        emit StateSet(id, state);
    }

    /**
    * @notice Enable/Disable collection buyability using BNB
    * @param id collection id
    * @param state true if buying by BNB is allowed
    */
    function setBnbBuying(uint256 id, bool state) external onlyOwner {
        MysteryBox.Collection storage c = collections[id];
        c.setBnbBuying(state);

        emit BnbBuyingSet(id, state);
    }

    /**
    * @notice Sets discounts applied based on batch minted amounts
    * @param amounts amounts to apply the discounts to
    * @param sales percents to be discounted from the full price (e.g. 25 tokens -> 5 % discount => [25], [5])
    */
    function setSales(uint256[] memory amounts, uint256[] memory sales) external onlyOwner {
        require(amounts.length == sales.length, "Array length mismatch");
        for(uint256 i=0; i<amounts.length; i++) {
            sale[amounts[i]] = sales[i];
        }
    }

    /**
    * @notice Sets the address allowed to withdraw the proceeds from presale
    * @param _receiverOfEarnings address of the reveiver
    */
    function setReceiverOfEarnings(address payable _receiverOfEarnings)
        external
        onlyOwner
    {
        require(
            _receiverOfEarnings != receiverOfEarnings,
            "Receiver already configured"
        );
        require(_receiverOfEarnings != address(0), "Receiver cannot be 0");
        receiverOfEarnings = _receiverOfEarnings;
    }

    /**
    * @notice Sets the admin address
    * @param account address of the admin
    */
    function setAdmin(address account)
        external
        onlyOwner
    {
        require(
            account != admin,
            "Account already configured"
        );
        require(account != address(0), "Account cannot be 0");
        admin = account;
    }

    /**
    * @notice Allows setting the stablecoin used for price calculations
    * @param token address of the stablecoin
    */
    function setStablecoin(address token) external onlyOwner {
        require(token != address(0), "Cannot be 0");

        stablecoin = token;
    }

    /**
    * @notice Sets new URI for the collection
    * @param newuri New URI following the standard https://eips.ethereum.org/EIPS/eip-1155#metadata
    */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
    * @notice Sets contract metadata URI
    * @param newuri new contract metadata uri */
    function setContractMetadataURI(string memory newuri) external onlyOwner {
        _contractMetadataURI = newuri;
    }

    /**
    * @notice Configure NFTPussies contract address 
    * @param nftp_ NFTP contract address
    */
    function setNftp(address nftp_) external onlyOwner {
        require(IPussiesNFT(nftp_).totalSupply() >= 0, "May not be NFTP");
        nftp = IPussiesNFT(nftp_);
    }

    /**
    * @notice Configures address of the token used to pay for boxes
    * @param token address of the token
    */
    function setPaidWith(address token) external onlyOwner {
        require(token != address(0), "Cannot be 0");
        paidWith = IERC20(token);
    }

    /**
    * @notice Configures address of the prices contract
    * @param prices_ prices contract address
    */
    function setPrices(address prices_) external onlyOwner {
        require(prices_ != address(0), "Cannot be 0");
        prices = IPrices(prices_);
    }


    //===================== EXTERNAL RESTRICTED =====================

    /**
    * @notice Allows receiverofEarnings to withdraw funds from the contract
    */
    function withdraw() external {
        require(
            msg.sender == receiverOfEarnings,
            "Sender not allowed to withdraw"
        );

        uint256 bnbBalance = address(this).balance;
        uint256 balance = paidWith.balanceOf(address(this));

        if (bnbBalance > 0) {
            payable(receiverOfEarnings).transfer(bnbBalance);
        }

        if (balance > 0) {
            require(paidWith.transfer(receiverOfEarnings, balance), "Transfer failed");
        }

    }

    /**
    * @notice Allows admin wallet to fulfill the reveal request
    * @param counter number of the request to process
    * @param seed random number provided by admin
    */
    function revealFulfill(uint256 counter, uint256 seed) external onlyAdmin {
        RevealRequestInfo memory info = revealRequests[counter];
        require(info.account != address(0), "Wrong counter");
        MysteryBox.Collection storage c = collections[info.collectionId];

        if (balanceOf(info.account, info.collectionId) >= info.amount && c.revealable()) {
            uint16[] memory rarities = new uint16[](info.amount);
            uint16[] memory photos = new uint16[](info.amount);

            uint16 photoCount = uint16(c.rarities[0].length);

            for(uint256 i=0; i<info.amount;) {
                uint256 semiRand = uint256(keccak256(abi.encodePacked(seed, i, block.number)));
                uint16 photoRand = uint16(semiRand % photoCount);

                RarityPhoto memory rp = _reveal(
                    info.collectionId,
                    photoCount,
                    photoRand,
                    uint16(semiRand % c.getCopies(photoRand))
                    );
                rarities[i] = rp.rarityGroup;
                photos[i] = rp.photo;
                unchecked {
                    ++i;
                }
            }

            _burn(info.account, info.collectionId, info.amount);
            uint256 start = nftp.mintBatch(info.account, info.collectionId, rarities, photos);
            uint256[] memory nftIds = new uint256[](info.amount);
            for(uint256 i=0; i<info.amount; ++i) {
                nftIds[i] = start + i;
            }
            emit Reveal(info.collectionId, nftIds, rarities, photos, info.account, counter);
        } else {
            emit RevealFailed(info.account, info.collectionId, info.amount, info.nonce);
        }

        delete revealRequested[info.account];
        delete revealRequests[counter];
        requestCounterStart++;

    }


    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized to perform the action");
        _;
    }

    //===================== EXTERNAL ANYONE ======================

    /**
    * @notice Returns max total amount of boxes in collection
    * @param id collection id
    * @return uint256 max total amount of boxes in collection
    */
    function getCap(uint256 id) external view returns(uint256) {
        return collections[id].cap;
    }

    /**
    * @notice Mints given amount of boxed and expects BNB as payment
    * @param id collection id
    * @param amount amount of boxes to be minted */
    function mint(uint256 id, uint256 amount) external payable {
        MysteryBox.Collection storage c = collections[id];
        require(c.bnbBuying, "Cannot buy with BNB");
        
        address[] memory path = new address[](2);
        
        path[0] = prices.WETH();
        path[1] = stablecoin;

        uint256 priceBNB = prices.getPrice(path);

        require(c.price == 0 || priceBNB > 0, "Error getting price");

        uint256 price = priceBNB == 0 ? 0 : c.price * 10**18 / priceBNB;
        uint256 cost = _getCost(price, amount);

        require(msg.value >= cost, "Not enouth BNB sent");
        _mint(c, id, amount);
        if (msg.value > cost) {
            uint256 ret = msg.value - cost;
            payable(msg.sender).transfer(ret);
        }

        emit BoxMint(id, amount, cost, msg.sender, true);
    }

    /**
    * @notice Get probable cost of the mint in paidWith token
    * @param id collection ID
    * @param amount number of boxes to mint
    * @return uint256 cost of mint
    */
    function getPrice(uint256 id, uint256 amount) external view returns(uint256) {
        return _getPrice(id, amount, true);
    }

    /**
    * @notice Get probable cost of the mint in BNB
    * @param id collection ID
    * @param amount number of boxes to mint
    * @return uint256 cost of mint in BNB
    */
    function getPriceBNB(uint256 id, uint256 amount) external view returns(uint256) {
        return _getPrice(id, amount, false);
    }

    /**
    * @notice Mints given amount of boxes and takes paidWith token based on current price
    * @param id collection id
    * @param amount amount of boxes to be minted
    */
    function mintWithToken(uint256 id, uint256 amount) external {
        MysteryBox.Collection storage c = collections[id];

        address[] memory path = new address[](3);
        uint256 paidWithPrice;
        
        path[0] = address(paidWith);
        path[1] = prices.WETH();
        path[2] = stablecoin;

        paidWithPrice = prices.getPrice(path);
        require(c.price == 0 || paidWithPrice > 0, "Error getting price");

        uint256 price = paidWithPrice == 0 ? 0 : c.price * 10**18 / paidWithPrice;
        uint256 cost = _getCost(price, amount);

        if (price > 0) {
            paidWith.transferFrom(msg.sender, address(this), cost);
        }

        _mint(c, id, amount);
        emit BoxMint(id, amount, cost, msg.sender, false);
    }

    /**
    * @notice Allows box owner to request a reveal
    * @param id collection id
    * @param amount number of boxes to reveal
    */
    function reveal(uint256 id, uint256 amount) external {
        require(balanceOf(msg.sender, id) >= amount, "Not enough MysteryBoxes");
        require(amount <= maxReveal, "Amount too high");
        MysteryBox.Collection storage c = collections[id];
        require(c.revealable(), "Cannot be revealed yet");
        require(revealRequested[msg.sender] == 0, "Account already requested");

        revealRequests[requestCounterEnd] = RevealRequestInfo(msg.sender, amount, id, requestCounterEnd);
        revealRequested[msg.sender] = requestCounterEnd;
        requestCounterEnd++;

        emit RevealRequest(msg.sender, id, amount, requestCounterEnd, block.timestamp);
    }

    /**
    * @notice Returns the Collection struct for given collection id
    * @param id collection id
    * @return MysteryBox.CollectionPublic the collection info
    */
    function getCollectionInfo(uint256 id) external view returns(MysteryBox.CollectionPublic memory) {
        MysteryBox.Collection memory tmp = collections[id];
        MysteryBox.CollectionPublic memory c = MysteryBox.CollectionPublic(
            tmp.rarities[0],
            tmp.rarities[1],
            tmp.rarities[2],
            tmp.rarities[3],
            tmp.cap,
            tmp.minted,
            tmp.price,
            tmp.revealTime,
            tmp.mintTime,
            tmp.maxBuy,
            tmp.mintable,
            tmp.initialized,
            tmp.bnbBuying
        );
        return c;
    }

    /**
    * @notice Provides information about how many NFTs were minted for each photo and rarity
    * @param id collection id
    * @return common Array of counts of minted NFTs in common rarity
    * @return rare Array of counts of minted NFTs in rare rarity
    * @return legendary Array of counts of minted NFTs in legendary rarity
    * @return puss Array of counts of minted NFTs in puss rarity
    */
    function getCollectionMinted(
        uint256 id
    ) public view returns(
        uint16[] memory common,
        uint16[] memory rare,
        uint16[] memory legendary,
        uint16[] memory puss
    ) {
        MysteryBox.Collection memory c = collections[id];

        common = new uint16[](c.rarities[0].length);
        rare = new uint16[](c.rarities[0].length);
        legendary = new uint16[](c.rarities[0].length);
        puss = new uint16[](c.rarities[0].length);

        for(uint16 i=0; i<c.rarities[0].length; i++) {
            common[i] = collectionPhotoRarityMinted[id][i][0];
            rare[i] = collectionPhotoRarityMinted[id][i][1];
            legendary[i] = collectionPhotoRarityMinted[id][i][2];
            puss[i] = collectionPhotoRarityMinted[id][i][3];
        }
    }

    /**
    * @notice Returns collection count
    * @return uint256 number of existing collections
    */
    function collectionsCount() external view returns(uint256) {
        return collections.length;
    }

    /**
    * @notice Returns discount per given amount
    * @param amount amount
    */
    function getSale(uint256 amount) external view returns(uint256) {
        return sale[amount];
    }


    function totalSupply() external view returns(uint256 result) {
        for(uint256 i=0; i<collections.length; i++) {
            result += collections[i].cap;
        }
    }

    //=================== INTERNAL ===================

    /**
    * @notice Mints given amount of MysteryBoxes for given collection
    * @param c MysteryBox collection
    * @param id collection id
    * @param amount amount of boxes to mint
    */
    function _mint(MysteryBox.Collection storage c, uint256 id, uint256 amount) internal nonReentrant {
        require(c.isOpen(), "Collection not mintable");    
        require(c.belowCap(amount), "Cap reached");
        require(c.maxBuy == 0 || amount <= c.maxBuy, "Amount too high");

        c.minted += amount;        
        _mint(msg.sender, id, amount, "");
    }

    /**
    * @notice Calculates price of the batch minted tokens incorporating discount
    * @param price price per token
    * @param amount number of tokens to buy
    */
    function _getCost(uint256 price, uint256 amount) internal view returns(uint256) {
        return (price * amount * (100 - sale[amount])) / 100;
    }

    /**
    * @notice Get probable cost of the mint
    * @param id collection ID
    * @param amount number of boxes to mint
    * @param toStable true if the we are looking for price in stablecoin
    * @return uint256 cost of mint
    */
    function _getPrice(uint256 id, uint256 amount, bool toStable) internal view returns(uint256) {
        MysteryBox.Collection storage c = collections[id];

        uint256 length = toStable ? 3 : 2;
        address[] memory path = new address[](length);
        uint256 paidWithPrice;
        
        path[0] = address(paidWith);
        path[1] = prices.WETH();
        if (toStable) {
            path[2] = stablecoin;
        }

        paidWithPrice = prices.getPriceNoUpdate(path);

        uint256 price = paidWithPrice == 0 ? 0 : c.price * 10**18 / paidWithPrice;

        return _getCost(price, amount);
    }

    /**
    * @notice Performs the reveal - generates random rarity, mints final NFT, burns the box
    * @param id  collection Id
    * @param photoCount number of photos in collection
    * @param photoRand random number for selecting photo
    * @param rarityRand random number for selecting rarity*/
    function _reveal(uint256 id, uint16 photoCount, uint16 photoRand, uint16 rarityRand) internal nonReentrant returns(RarityPhoto memory rp) {
        MysteryBox.Collection storage c = collections[id];

        bool minted;

        rp = RarityPhoto(
                rarityRand,
                photoRand,
                0,
                0
            );

        while(!minted) {
            //Find the rarity where the random number fits in
            for(uint16 i=rp.raritySum; i < MysteryBox.RARITY_COUNT; i++) {
                rp.raritySum += c.rarities[i][rp.photo];
                if(rp.rarity < rp.raritySum) {
                    rp.rarityGroup = i;
                    break;
                }
            }

            //Check if there is space in collection -> rarity -> photo group
            if(collectionPhotoRarityMinted[id][rp.photo][rp.rarityGroup] + 1 <= c.rarities[rp.rarityGroup][rp.photo]) {
                collectionPhotoRarityMinted[id][rp.photo][rp.rarityGroup]++;
                minted = true;
                break;
            } 

            //If we could not mint, increase rarity or try different photo group
            if(!minted) {
                if (rp.rarity % 2 > 0) {
                    rp.rarityGroup++;
                    if (rp.rarityGroup >= MysteryBox.RARITY_COUNT) {
                        rp.photo = (rp.photo + 1) % photoCount;
                        rp.rarityGroup %= MysteryBox.RARITY_COUNT;
                    }
                } else {
                    rp.photo++;
                    if (rp.photo >= photoCount) {
                        rp.photo %= photoCount;
                        rp.rarityGroup = (rp.rarityGroup + 1) % MysteryBox.RARITY_COUNT;
                    }
                }
            }
        }

        require(minted, "Reveal failed");


    }

    /**
    * @notice Provides contract metadata URI
    * @return contract metadata uri */
    function contractURI() external view returns (string memory) {
        return _contractMetadataURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Import/ERC721.sol";

interface IPussiesNFT {
    function mintBatch(address to, uint256 collection, uint16[] memory rarity, uint16[] memory photo) external returns(uint256 start);
    function totalSupply() external view returns(uint256);
    function getInfo(uint256 id) external view returns(uint256 collection, uint16 rarity, uint16 photo);
}

contract PussiesNFT is IPussiesNFT, ERC721, Ownable {
    using Strings for uint256;
    using Strings for uint16;

    string private _contractMetadataURI;

    string public baseURI;
    address public mysteryBox;

    mapping(uint256 => uint16) internal rarities;
    mapping(uint256 => uint16) internal photos;
    mapping(uint256 => uint256) internal collections;

    mapping(address => uint256[]) public tokensByOwner;
    uint256 internal _totalSupply;

    struct TokenInfo {
        uint256 tokenId;
        uint256 collectionId;
        uint16 rarity;
        uint16 photoId;
    }


    constructor(string memory contractMetadataURI) ERC721("NFT Pussies", "NFTP") {
        _contractMetadataURI = contractMetadataURI;
    }

    /**
    * @notice Mints batch of NFTs, only callable by mysteryBox contract
    * @param to recipient of the NFT
    * @param collection collection id the token belongs to
    * @param rarity rarities of the tokens
    * @param photo photo ids of the tokens
    */
    function mintBatch(address to, uint256 collection, uint16[] calldata rarity, uint16[] calldata photo) external returns(uint256 start) {
        require(msg.sender == mysteryBox, "Cannot mint");
        require(to != address(0), "ERC721: mint to the zero address");
        require(rarity.length == photo.length, "Length mismatch");
        uint256 length = rarity.length;

        _balances[to] += length;
        uint256 tokenId = _totalSupply;
        start = tokenId;

        for (uint256 i=0; i<length;) {
            _owners[tokenId] = to;
            rarities[tokenId] = rarity[i];
            photos[tokenId] = photo[i];
            collections[tokenId] = collection;
            addTokenToOwner(to, tokenId);

            emit Transfer(address(0), to, tokenId);
            tokenId = ++_totalSupply;
            unchecked {
                ++i;
            }
        }

        
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to) {
            removeTokenFromOwner(from, tokenId);
        }
        if (to != address(0) && to != from) {
            addTokenToOwner(to, tokenId);
        }
    }

    /**
    * @notice Removes a tokenId from a list of NFTs owned by user
    * @param account address of the NFT owner
    * @param tokenId token to remove from user
    */
    function removeTokenFromOwner(address account, uint256 tokenId) internal {
        uint256 l = tokensByOwner[account].length;
        for(uint256 i=0; i<l;) {
            if (tokensByOwner[account][i] == tokenId) {
                if (l > 1) {
                    tokensByOwner[account][i] = tokensByOwner[account][l-1];
                }
                tokensByOwner[account].pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
    * @notice Adds a tokenId to list of NFTs owned by user
    * @param account address of the NFT owner
    * @param tokenId token to map to user */
    function addTokenToOwner(address account, uint256 tokenId) internal {
        tokensByOwner[account].push(tokenId);
    }

    /**
    * @notice Returns basic information about the token
    * @param id token id
    * @return collection collection id
    * @return rarity token rarity
    * @return photo image of the token
    */
    function getInfo(uint256 id) external view returns(uint256 collection, uint16 rarity, uint16 photo) {
        require(_exists(id), "Token does not exist");

        rarity = rarities[id];
        collection = collections[id];
        photo = photos[id];
    }

    /**
    * @notice Get number of tokens per collection
    * @param collectionsCount Number of existing collections
    * @return uint256[] List of numbers representing minted tokens for each collection
    */
    function collectionTokenCount(uint256 collectionsCount) public view returns(uint256[] memory) {
        uint256[] memory ids = new uint256[](collectionsCount);
        for(uint256 j=0; j<_totalSupply; j++) {
            ids[collections[j]]++; 
        }

        return ids;
    }

    /**
    * @notice Returns list of tokens in a given collection
    * @param collectionId collection id
    * @param collectionsCount total number of existing collections
    * @return uint256[] list of tokens for given collection
    */
    function tokensInCollection(uint256 collectionId, uint256 collectionsCount) external view returns(uint256[] memory) {
        uint256[] memory counts = collectionTokenCount(collectionsCount);
        uint256[] memory ids = new uint256[](counts[collectionId]);

        uint256 cnt;
        for(uint256 i=0; i<_totalSupply; i++) {
            if(collections[i] == collectionId) {
                ids[cnt] = i;
                cnt++;
            }
        }

        return ids;
    }

        /**
    * @notice Returns list of tokens in a given collection
    * @param collectionId collection id
    * @param collectionsCount total number of existing collections
    * @return TokenInfo[] list of tokens for given collection
    */
    function tokensInCollectionInfo(uint256 collectionId, uint256 collectionsCount) external view returns(uint256[] memory) {
        uint256[] memory counts = collectionTokenCount(collectionsCount);
        uint256[] memory infos = new uint256[](counts[collectionId]);

        uint256 cnt;
        for(uint256 i=0; i<_totalSupply; i++) {
            if(collections[i] == collectionId) {
                infos[cnt] = i;
                cnt++; 
            } 
        }

        return infos;
    }

    function getTokensByOwner(address account) external view returns(uint256[] memory) {
        return tokensByOwner[account];
    }

    /**
    * @notice Allows setting new MysteryBox contract address
    * @param account address of the mysteryBox contract
    */
    function setMysteryBox(address account) external onlyOwner {
        require(account != address(0), "MysteryBox address cannot be 0");
        mysteryBox = account;
    }

    /**
    * @notice Sets new base uri
    * @param uri_ new base uri
    */
    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    /**
    * @notice Sets contract metadata URI
    * @param newuri new contract metadata uri */
    function setContractMetadataURI(string memory newuri) external onlyOwner {
        _contractMetadataURI = newuri;
    }

    /**
    * @notice Returns token uri based ony tokenId
    * @param tokenId id of the token
    * @return URI leading to the token metadata
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, collections[tokenId].toString(), "/", rarities[tokenId].toString(), "/", photos[tokenId].toString(), "/")) : "";
    }

    /**
    * @notice Returns total supply of the tokens minted
    * @return uint256 total supply
    */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @notice Provides contract metadata URI
    * @return contract metadata uri */
    function contractURI() external view returns (string memory) {
        return _contractMetadataURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrices {
    function WETH() external view returns (address);
    function getPrice(address[] memory path) external returns(uint256);
    function getPriceNoUpdate(address[] memory path) external view returns(uint256);
    function getSpot(address token1, address token2) external view returns(uint256);
    function getTwap(address token1, address token2) external view returns(uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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