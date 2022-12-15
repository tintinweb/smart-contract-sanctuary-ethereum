// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IHashes} from "../../interfaces/IHashes.sol";
import {IHashesDAO} from "../../interfaces/IHashesDAO.sol";

/// @title  TrashBin
/// @author Cooki.eth
/// @notice This contract fulfils the role of being the buyer of last resort for ERC721 and ERC1155 NFTs.
///         Any owner of an NFT that conforms to the ERC721 or ERC1155 token standards can sell their NFT
///         to this contract in exchange for the specified sellPrice. This can be achieved by either
///         safe transfering their NFT to this contract, or by granting the contract approval to transfer
///         their NFT and executing the sell function. After an NFT has been sold to this contract
///         anyone may purchase it from the contract in exchange for the buyPrice. Discounts on purchases
///         of NFTs from this contract are available for Hashes NFT holders, with DAO hashes holders
///         getting a higher discount than standard hash holders.
contract TrashBin is Ownable, IERC721Receiver, IERC1155Receiver, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    /////////////
    //Variables//
    /////////////

    /// @notice A struct used to store all of the relevant information about an NFT sold to this contract.
    ///         The information recorded is the collection address of the NFT, the token ID of the NFT, a
    ///         boolean to distinguish between ERC721 and ERC1155 NFTs ("true" if it is an ERC721 and false
    ///         if it is an ERC1155), and the block that the NFT was sold to the contract.
    struct nft {
        address collection;
        uint256 id;
        bool isERC721;
        uint256 blockSold;
    }

    /// @notice The array of NFT information used to store data about NFTs currently held by this contract.
    nft[] public nftStorage;

    /// @notice The base price, in wei, for a user to buy an NFT from this contract.
    uint256 public buyPrice;

    /// @notice The price, in wei, any user will receive for selling an NFT to this contract.
    uint256 public sellPrice;

    /// @notice The multiplier discount, in basis points, that a standard hashes NFT holder will receive
    ///         when purchasing an NFT from this contract.
    uint256 public standardHashDiscount;

    /// @notice The multiplier discount, in basis points, that a DAO hashes NFT holder will receive when
    ///         purchasing an NFT from this contract.
    uint256 public daoHashDiscount;

    /// @notice The time delay, in blocks, that must pass for an NFT to be buyable after it has been sold
    ///         to this contract. This allows NFTs sent to the contract by mistake to be recoverable before
    ///         being bought.
    uint256 public buyableDelay;

    /// @notice The minimum balance, in wei, that the contract retains after the owner multi-sig withdraws
    ///         ETH that has been earned by the contract.
    uint256 public minEthBalance;

    /// @notice The maximum balance, in wei, that the contract retains after purchases are made from the 
    ///         the contract. If the max balance is exceeded, the ETH will automatically be withdrawn via
    ///         a buy. 
    uint256 public maxEthBalance;

    /// @notice The percentage, in basis points, of profits retained by the owner multi-sig.
    uint256 public ethPercentageToOwner;

    /// @notice The Hashes NFT collection address.
    IHashes public hashes;

    /// @notice The Hashes DAO contract address.
    IHashesDAO public hashesDAO;

    //////////
    //Events//
    //////////

    /// @notice The total amount of ETH withdrawn when the withdrawETH function is called.
    event WithdrawETH(uint256 indexed _amountWithdrawn);

    /// @notice Details emitted following a removal of an NFT from the contract. These are the collection address and
    ///         the token id.
    event RemoveNFT(address indexed _collection, uint256 indexed _id);

    /// @notice Details emitted following a removal of an ERC721 from the contract via the failsafe function withdrawERC721. 
    ///         These are the collection address and token id of the NFT.
    event WithdrawERC721(IERC721 indexed _collection, uint256 indexed _id);

    /// @notice Details emitted following a removal of an ERC1155 from the contract via the failsafe function withdrawERC1155. 
    ///         These are the collection address, token id, and amount transferred of the NFT.
    event WithdrawERC1155(IERC1155 indexed _collection, uint256 indexed _id, uint256 indexed _amount);

    /// @notice Details emitted following a removal of an ERC20 from the contract via the failsafe function withdrawERC20. 
    ///         These are the token address and amount of tokens.
    event WithdrawERC20(IERC20 indexed _token, uint256 indexed _amount);

    /// @notice Details emitted following a removal of an Index from the contract via the failsafe function deleteIndex. 
    ///         These are the collection address, token id.
    event DeleteIndex(address indexed _collection, uint256 indexed _id);

    /// @notice Details emitted following a settings update. These details are the name of the setting updated, the 
    ///         former value, and the new value after the update.
    event UpdatedSetting(string indexed _setting, uint256 indexed _old, uint256 indexed _new);

    /// @notice Details emitted following a purchase. These are the collection address, token id, and whether
    ///         or not it was an ERC721 (_isERC721 = true) or an ERC1155 (_isERC721 = false) NFT.
    event Purchase(address indexed _collection, uint256 indexed _id, bool indexed _isERC721);

    /// @notice Details emitted following a sale. These are the collection address, token id, whether or not
    ///         it was an ERC721 (_isERC721 = true) or an ERC1155 (_isERC721 = false) NFT, and the block number
    ///         when the NFT was sold.
    event Sale(address indexed _collection, uint256 indexed _id, bool indexed _isERC721, uint256 _blockSold);

    /////////////////////////////
    //Modifiers and Constructor//
    /////////////////////////////

    /// @notice Unique modifier to only allow owner multi-sig or the Hashes DAO to execute the transfer ownership
    ///         function.
    modifier onlyOwnerOrHashesDAO() {
        require(
            _msgSender() == owner() || _msgSender() == address(hashesDAO),
            "TrashBin: must be contract owner or Hashes DAO"
        );
        _;
    }

    /// @notice Unique modifier to allow anyone to call when not paused and only the Owner to call a function when paused.
    modifier pausedOnlyOwner() {
        if (paused()) {
            _checkOwner();
        }
        _;
    }

    /// @notice Constructor of the contract. Both the Hashes NFT, DAO contract, and owner addresses must be
    ///         provided, while the other initial settings are defined.
    constructor(IHashes _hashes, IHashesDAO _hashesDAO, address _owner) {
        _transferOwnership(_owner);
        hashes = _hashes;
        hashesDAO = _hashesDAO;
        buyPrice = 0.02e18 wei;
        sellPrice = 100 wei;
        standardHashDiscount = 7500;
        daoHashDiscount = 2500;
        buyableDelay = 20000;
        minEthBalance = 0.001e18 wei;
        maxEthBalance = 0.1e18 wei;
        ethPercentageToOwner = 2000;
    }

    /////////////////////
    //Primary Functions//
    /////////////////////

    /// @notice This function allows anyone to purchase multiple NFTs that have been sold to this contract. If the 
    ///         contract owns more ETH than the maxEthBalance amount, an auto-withdraw of ETH will be triggered.
    /// @param indexes An array of indexes that correspond to the nftStorage array of NFTs that the purchaser
    ///                wishes to purchase. The indexes in this array must be monotonically decreasing.
    /// @param hashId  An array that allows the purchaser to enter a Hashes NFT ID that they own in order to receive
    ///                a discount on their purchase. If this array is empty the purchaser will pay the full price.
    ///                If this array has more than one entry, or if the Hashes NFT ID entered is not owned by the 
    ///                purchaser the function will not succeed. DAO Hashes NFT owners will receive the DAO hash
    ///                discount while standard Hashes NFT owners will receive the standard hash discount.
    function buy(uint256[] memory indexes, uint256[] memory hashId) external payable whenNotPaused nonReentrant {
        require(
            msg.value >= (_getPriceWithHash(_msgSender(), hashId) * indexes.length),
            "TrashBin: insufficient ETH payment."
        );

        require(
            indexes.length <= 100,
            "TrashBin: a maximum of 100 purchases per transaction."
        );

        for (uint256 i = 0; i < indexes.length; i++) {
            require(
                indexes[i] < nftStorage.length,
                "TrashBin: index out of bounds."
            );

            nft memory boughtNFT = nftStorage[indexes[i]];

            require(
                block.number > (boughtNFT.blockSold + buyableDelay),
                "TrashBin: insufficient time has passed since sale of this NFT."
            );

            if (boughtNFT.isERC721) {
                IERC721 collectionAddress = IERC721(boughtNFT.collection);

                collectionAddress.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    boughtNFT.id
                );
            } else {
                IERC1155 collectionAddress = IERC1155(boughtNFT.collection);

                collectionAddress.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    boughtNFT.id,
                    1,
                    "0x"
                );
            }

            emit Purchase(
                boughtNFT.collection,
                boughtNFT.id,
                boughtNFT.isERC721
            );
        }

        for (uint256 j = 0; j < indexes.length; j++) {
            if (j > 0) {
                require(
                    indexes[j - 1] > indexes[j],
                    "Trashbin: indexes array provided is not monotonically decreasing."
                );
            }
            
            nftStorage[indexes[j]] = nftStorage[(nftStorage.length - 1)];
            nftStorage.pop();
        }

        if (address(this).balance > maxEthBalance) {
            _withdrawETH();
        }
    }

    /// @notice This function allows anyone to sell multiple NFTs (either ERC721 or ERC1155) to this contract. Each NFT
    ///         will be sold for the same sell price defined by the sellPrice variable. While the NFTs do not all have to be
    ///         from the same collection, approval for each NFT must be granted to this contract in order for the user to
    ///         sell the NFTs. The collection array, tokenIds array, amounts array, and isERC721s array must be of the same
    ///         length, and the relative index position of each must correspond. For instance: 
    ///         collection array = (NFT-A address, NFT-B address, NFT-C address)
    ///         tokenIds array = (NFT-A token Id, NFT-B token Id, NFT-C token Id)
    ///         amounts array = (NFT-A amount, NFT-B amount, NFT-C amount)
    ///         isERC721s array = (NFT-A isERC721, NFT-B isERC721, NFT-C isERC721)
    /// @param collection An array of contract addresses for each of the NFTs to be sold.
    /// @param tokenIds   An array of token Ids that corresponds to the collection array.
    /// @param amounts    An array of the amounts of each token Id to be sold. When the NFT is an ERC721 the amount is
    ///                   inconsequential because each token Id only has one token associated with it. For ERC1155s however,
    ///                   the amount may be greater than 1, but should (in most cases) equal 1.
    /// @param isERC721s  An array of boolean values specifying whether or not the collection is an ERC721 (true), or an
    ///                   an ERC1155 (false).
    function sell(address[] memory collection, uint256[] memory tokenIds, uint256[] memory amounts, bool[] memory isERC721s) external {
        require(
            (collection.length == tokenIds.length) && (tokenIds.length == amounts.length) && (amounts.length == isERC721s.length),
            "TrashBin: All arrays must be the same length."
        );

        require(
            collection.length <= 100,
            "TrashBin: a maximum of 100 collections per transaction."
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {

            if (isERC721s[i]) {
                
                IERC721 nftCollection = IERC721(collection[i]);

                require(
                    (nftCollection.getApproved(tokenIds[i]) == address(this) || nftCollection.isApprovedForAll(_msgSender(), address(this))),
                    "TrashBin: TrashBin is not approved to transfer ERC721 NFT."
                );

                nftCollection.safeTransferFrom(
                    _msgSender(),
                    address(this),
                    tokenIds[i]
                );
            } else {

                require(
                    amounts[i] <= 100,
                    "TrashBin: a maximum of 100 sales per collection."
                );
                
                IERC1155 nftCollection = IERC1155(collection[i]);

                require(
                    nftCollection.isApprovedForAll(_msgSender(), address(this)),
                    "TrashBin: TrashBin is not approved to transfer ERC1155 NFTs."
                );

                nftCollection.safeTransferFrom(
                    _msgSender(),
                    address(this),
                    tokenIds[i],
                    amounts[i],
                    "0x"
                );
            }
        }
    }
    
    /// @notice This function allows anymore to withdraw the revenue from this contract and distribute it to the
    ///         Hashes DAO and owner multi-sig. The owner multi-sig will receive their percentage of the revenue 
    ///         in accordance with the ethPercentage variable and the remaining will be distributed to the Hashes
    ///         DAO. A minimum amount of ETH, as defined by the minETHBalance variable, will remain in the contract.
    function withdrawETH() external pausedOnlyOwner nonReentrant {
        _withdrawETH();
    }

    /// @notice This function allows DAO Hashes holders to remove an NFT for sale and send the NFT to the owner 
    ///         multi-sig. This allows valuable NFTs accidently sent to the contract to be easily removed from sale
    ///         during the buyable delay period.
    /// @param index The index of the NFT in the nftStorage array to be removed.
    /// @param hashId The hashes NFT ID used to verify ownership of a DAO hash.
    function removeNFT(uint256 index, uint256 hashId) external whenNotPaused nonReentrant {
        require(index < nftStorage.length, "TrashBin: index out of bounds.");

        require(
            hashes.ownerOf(hashId) == msg.sender,
            "TrashBin: message sender does not own the Hashes NFT provided."
        );

        require(
            (hashId < hashes.governanceCap()) && !hashes.deactivated(hashId),
            "TrashBin: Hashes NFT Id provided is not a DAO NFT."
        );

        nft memory removedNFT = nftStorage[index];

        nftStorage[index] = nftStorage[(nftStorage.length - 1)];
        nftStorage.pop();

        if (removedNFT.isERC721) {
            IERC721 collectionAddress = IERC721(removedNFT.collection);

            collectionAddress.safeTransferFrom(
                address(this),
                owner(),
                removedNFT.id
            );
        } else {
            IERC1155 collectionAddress = IERC1155(removedNFT.collection);

            collectionAddress.safeTransferFrom(
                address(this),
                owner(),
                removedNFT.id,
                1,
                "0x"
            );
        }

        emit RemoveNFT(removedNFT.collection, removedNFT.id);
    }

    /// @notice This function allows for an easy way of seeing the number of NFTs held for sale by this contract.
    /// @return uint256 The length of the nftStorage array.
    function nftStorageLength() external view returns (uint256) {
        return nftStorage.length;
    }

    /// @notice This function allows for an easy way of seeing if an NFT (determined via an index) is available to buy.
    /// @param  index An index in the nftStroage array.
    /// @return bool A boolean of whether or not the NFT is available to be bought.
    function isNFTAvailableToBuy(uint256 index) external view returns (bool) {
        require(
            index < nftStorage.length,
            "TrashBin: index out of bounds."
        );

        require(
           paused() == false,
           "TrashBin: paused."
        );

        return (block.number > (nftStorage[index].blockSold + buyableDelay)) ? true : false;
    }

    /// @notice This function allows for users to find the index of an NFT held by this contract. The user provides the
    ///         collection address, NFT id, and starting index and the function will test up to 1000 nfts in the nftStorage
    ///         array to find it's location index.
    /// @param  collection The contract address of the NFT to be located.
    /// @param  id The id of NFT to be located.
    /// @param  startingIndex An index in the nftStorage array to begin searching.   
    /// @return uint256 The index of the nft in the nftStorage array
    function getNFTStorageIndex(address collection, uint256 id, uint256 startingIndex) external view returns (uint256) {
        require(
            startingIndex < nftStorage.length,
            "TrashBin: starting index out of bounds."
        );

        uint256 index = startingIndex;

        while ((index < nftStorage.length) && (index < (startingIndex + 1000))) {
            if ((nftStorage[index].collection == collection) && (nftStorage[index].id == id)) {
                return index;
            }
            
            index++;
        }

        revert("NFT index not located. Check that the collection and id values are correct, and/or choose a different starting index.");
    }

    //////////////////////
    //Failsafe Functions//
    //////////////////////

    /// @notice The function allows the owner multi-sig to retrieve any ERC721 NFTs incorrectly sent to the contract.
    /// @param collection The ERC721 collection address.
    /// @param id         The token id of the NFT.
    function withdrawERC721(IERC721 collection, uint256 id) external onlyOwner {
        collection.safeTransferFrom(address(this), owner(), id);

        emit WithdrawERC721(collection, id);
    }

    /// @notice The function allows the owner multi-sig to retrieve any ERC1155 NFTs or tokens incorrectly sent to the contract.
    /// @param collection The ERC1155 collection address.
    /// @param id         The token id of the NFT or token.
    /// @param amount     The amount of tokens to be retrieved.
    function withdrawERC1155(IERC1155 collection, uint256 id, uint256 amount) external onlyOwner {
        collection.safeTransferFrom(address(this), owner(), id, amount, "0x");

        emit WithdrawERC1155(collection, id, amount);
    }

    /// @notice The function allows the owner multi-sig to retrieve any ERC20 tokens incorrectly sent to the contract.
    /// @param token    The ERC20 token address.
    /// @param amount   The amount of tokens to be retrieved.
    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);

        emit WithdrawERC20(token, amount);
    }

    /// @notice The function allows the owner multi-sig to delete an array of indexes from the nftStorage array. Ideally, this 
    ///         function will never be needed, but in the event that an NFT is incorrectly withdrawn and a nftStorage
    ///         array entry persists this function can be used to remove the unnecessary index. The indexes array provided
    ///         must be monotonically decreasing.
    /// @param indexes The index array to be deleted. It must be monotonically decreasing.
    function deleteIndexes(uint256[] memory indexes) external onlyOwner {
        for (uint256 j = 0; j < indexes.length; j++) {
            require(indexes[j] < nftStorage.length, "TrashBin: index out of bounds.");

            if (j > 0) {
                require(
                    indexes[j - 1] > indexes[j],
                    "Trashbin: indexes array provided is not monotonically decreasing."
                );
            }

            nft memory correspondingData = nftStorage[indexes[j]];
            
            nftStorage[indexes[j]] = nftStorage[(nftStorage.length - 1)];
            nftStorage.pop();

            emit DeleteIndex(correspondingData.collection, correspondingData.id);
        }
    }

    /////////////////////////////////
    //Lower Level Primary Functions//
    /////////////////////////////////

    function _sellERC721(address collection, uint256 tokenId) internal whenNotPaused nonReentrant {
        nft memory newSale = nft(collection, tokenId, true, block.number);

        nftStorage.push(newSale);

        emit Sale(collection, tokenId, true, block.number);
    }

    function _sellERC1155(address collection, uint256 tokenId) internal whenNotPaused nonReentrant {
        nft memory newSale = nft(collection, tokenId, false, block.number);

        nftStorage.push(newSale);

        emit Sale(collection, tokenId, false, block.number);
    }

    function _getPriceWithHash(address buyer, uint256[] memory hashesId) internal view returns (uint256) {
        if (hashesId.length == 0) {
            return buyPrice;
        }

        require(
            hashesId.length == 1,
            "TrashBin: more than one Hashes NFT provided."
        );

        require(
            hashes.ownerOf(hashesId[0]) == buyer,
            "TrashBin: buyer does not own hashes NFT provided."
        );

        if ((hashesId[0] < hashes.governanceCap()) && !hashes.deactivated(hashesId[0])) {
            if (daoHashDiscount == 0) {
                return 0;
            }

            return ((buyPrice * daoHashDiscount) / 10000);
        }

        if (standardHashDiscount == 0) {
            return 0;
        }

        return ((buyPrice * standardHashDiscount) / 10000);
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;

        require(
            balance > minEthBalance,
            "TrashBin: contract balance is less than minimum balance amount."
        );

        uint256 totalWithdrawAmount = balance - minEthBalance;
        uint256 ownerFee = 0;

        if (ethPercentageToOwner > 0) {
            ownerFee = (totalWithdrawAmount * ethPercentageToOwner) / 10000;

            (bool success, ) = (owner()).call{value: ownerFee * 1 wei}("");
            require(success, "TrashBin: transfer to owner failed.");
        }

        uint256 hashesFee = totalWithdrawAmount - ownerFee;

        (bool success0, ) = (address(hashesDAO)).call{value: hashesFee * 1 wei}("");
        require(success0, "TrashBin: transfer to Hashes failed.");

        emit WithdrawETH(totalWithdrawAmount);
    }

    //////////////////////
    //Settings Functions//
    //////////////////////

    /// @notice This function allows the owner to pause or unpause the core functionality of the contract.
    ///         The functions that will be paused/unpaused are the 
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /// @notice This function allows the multi-sig owner to update all of the settings in a single transaction.
    /// @param newBuyPrice             The updated purchase price of an NFT (in wei).
    /// @param newSellPrice            The updated sale price of an NFT (in wei).
    /// @param newStandardHashDiscount The updated standard hash discount for purchases (in basis points).
    /// @param newDaoHashDiscount      The updated DAO hash discount for purchases (in basis points).
    /// @param newBuyableDelay         The updated buyable delay after an NFT sale for purchases (in blocks).
    /// @param newMinEthBalance        The updated minimum ETH balance that this contract retains after ETH withdrawals (in wei).
    /// @param newMaxEthBalance        The updated maximum ETH balance that this contract retains before ETH withdrawals (in wei).
    /// @param newEthPercentageToOwner The updated ETH percentage of revenue that is distributed to the owner multi-sig (in basis points).
    function updateAllSettings(
        uint256 newBuyPrice,
        uint256 newSellPrice,
        uint256 newStandardHashDiscount,
        uint256 newDaoHashDiscount,
        uint256 newBuyableDelay,
        uint256 newMinEthBalance,
        uint256 newMaxEthBalance,
        uint256 newEthPercentageToOwner
    ) external onlyOwner {
        _updateBuyPrice(newBuyPrice);
        _updateSellPrice(newSellPrice);
        _updateStandardHashDiscount(newStandardHashDiscount);
        _updateDaoHashDiscount(newDaoHashDiscount);
        _updateBuyableDelay(newBuyableDelay);
        _updateMinEthBalance(newMinEthBalance);
        _updateMaxEthBalance(newMaxEthBalance);
        _updateEthPercentageToOwner(newEthPercentageToOwner);
    }

    /// @notice This function allows the owner to change the buyPrice variable for each NFT purchase.
    /// @param newBuyPrice The updated buy price in wei.
    function updateBuyPrice(uint256 newBuyPrice) external onlyOwner {
        _updateBuyPrice(newBuyPrice);
    }

    /// @notice This function allows the owner to change the sellPrice variable for each NFT sale.
    /// @param newSellPrice The updated sell price in wei.
    function updateSellPrice(uint256 newSellPrice) external onlyOwner {
        _updateSellPrice(newSellPrice);
    }

    /// @notice This function allows the owner to change the standard Hashes NFT discount variable for each NFT sale.
    /// @param newStandardHashDiscount The updated discount multiplier in basis points.
    function updateStandardHashDiscount(uint256 newStandardHashDiscount) external onlyOwner {
        _updateStandardHashDiscount(newStandardHashDiscount);
    }

    /// @notice This function allows the owner to change the DAO Hashes NFT discount variable for each NFT sale.
    /// @param newDaoHashDiscount The updated discount multiplier in basis points.
    function updateDaoHashDiscount(uint256 newDaoHashDiscount) external onlyOwner {
        _updateDaoHashDiscount(newDaoHashDiscount);
    }

    /// @notice This function allows the owner to change the Buyable Delay variable after each NFT sale.
    /// @param newBuyableDelay The updated buyable delay in blocks.
    function updateBuyableDelay(uint256 newBuyableDelay) external onlyOwner {
        _updateBuyableDelay(newBuyableDelay);
    }

    /// @notice This function allows the owner to change the minETHBalance variable for this contract.
    /// @param newMinEthBalance The updated minimum ETH balance in wei.
    function updateMinEthBalance(uint256 newMinEthBalance) external onlyOwner {
        _updateMinEthBalance(newMinEthBalance);
    }

    /// @notice This function allows the owner to change the maxETHBalance variable for this contract.
    /// @param newMaxEthBalance The updated maximum ETH balance in wei.
    function updateMaxEthBalance(uint256 newMaxEthBalance) external onlyOwner {
        _updateMaxEthBalance(newMaxEthBalance);
    }

    /// @notice This function allows the owner to change the percentage of ETH revenue they receive when ETH is withdrawn
    ///         from the contract.
    /// @param newEthPercentageToOwner The updated owner percentage variable in basis points.
    function updateEthPercentageToOwner(uint256 newEthPercentageToOwner) external onlyOwner {
        _updateEthPercentageToOwner(newEthPercentageToOwner);
    }

    //////////////////////////////////
    //Lower Level Settings Functions//
    //////////////////////////////////

    function _updateBuyPrice(uint256 newBuyPrice) internal {
        require(
            (newBuyPrice >= 1000000000000) && (newBuyPrice <= 1e18),
            "TrashBin: newBuyPrice not within the lower and upper bounds."
        );

        uint256 oldBuyPrice = buyPrice;

        buyPrice = newBuyPrice * 1 wei;

        emit UpdatedSetting("buyPrice", oldBuyPrice, newBuyPrice);
    }

    function _updateSellPrice(uint256 newSellPrice) internal {
        require(
            (newSellPrice >= 1) && (newSellPrice <= 1000000000),
            "TrashBin: newSellPrice not within the lower and upper bounds."
        );

        uint256 oldSellPrice = sellPrice;

        sellPrice = newSellPrice * 1 wei;

        emit UpdatedSetting("sellPrice", oldSellPrice, newSellPrice);
    }

    function _updateStandardHashDiscount(uint256 newStandardHashDiscount) internal {
        require(
            newStandardHashDiscount <= 10000,
            "TrashBin: updated Standard Hash Discount may not exceed 100%."
        );

        uint256 oldStandardHashDiscount = standardHashDiscount;

        standardHashDiscount = newStandardHashDiscount;

        emit UpdatedSetting("standardHashDiscount", oldStandardHashDiscount, newStandardHashDiscount);
    }

    function _updateDaoHashDiscount(uint256 newDaoHashDiscount) internal {
        require(
            newDaoHashDiscount <= 10000,
            "TrashBin: updated DAO Hash Discount may not exceed 100%."
        );

        uint256 oldDaoHashDiscount = daoHashDiscount;

        daoHashDiscount = newDaoHashDiscount;

        emit UpdatedSetting("daoHashDiscount", oldDaoHashDiscount, newDaoHashDiscount);
    }

    function _updateBuyableDelay(uint256 newBuyableDelay) internal {
        require(
            (newBuyableDelay >= 10) && (newBuyableDelay <= 100000),
            "TrashBin: newBuyableDelay not within the lower and upper bounds."
        );

        uint256 oldBuyableDelay = buyableDelay;

        buyableDelay = newBuyableDelay;

        emit UpdatedSetting("buyableDelay", oldBuyableDelay, newBuyableDelay);
    }

    function _updateMinEthBalance(uint256 newMinEthBalance) internal {
        require(
            newMinEthBalance <= 0.1e18,
            "TrashBin: newMinEthBalance may not exceed 0.1ETH."
        );

        uint256 oldMinEthBalance = minEthBalance;

        minEthBalance = newMinEthBalance * 1 wei;

        emit UpdatedSetting("minEthBalance", oldMinEthBalance, newMinEthBalance);
    }

    function _updateMaxEthBalance(uint256 newMaxEthBalance) internal {
        require(
            (newMaxEthBalance >= 1000000000000) && (newMaxEthBalance <= 1e18),
            "TrashBin: newMaxEthBalance not within the lower and upper bounds."
        );

        uint256 oldMaxEthBalance = maxEthBalance;

        maxEthBalance = newMaxEthBalance * 1 wei;

        emit UpdatedSetting("maxEthBalance", oldMaxEthBalance, newMaxEthBalance);
    }

    function _updateEthPercentageToOwner(uint256 newEthPercentageToOwner) internal {
        require(
            newEthPercentageToOwner <= 10000,
            "TrashBin: updated ETH percentage may not exceed 100%."
        );

        uint256 oldEthPercentage = ethPercentageToOwner;

        ethPercentageToOwner = newEthPercentageToOwner;

        emit UpdatedSetting("ethPercentageToOwner", oldEthPercentage, newEthPercentageToOwner);
    }

    /////////////////////
    //Receive Functions//
    /////////////////////

    receive() external payable {}

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        address collection = msg.sender;

        require(
            IERC721(collection).ownerOf(tokenId) == address(this),
            "TrashBin: transfer to TrashBin failed."
        );

        _sellERC721(collection, tokenId);

        (bool success, ) = (from).call{value: sellPrice}("");
        require(success, "TrashBin: sale to depositor failed.");

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4) {
        address collection = msg.sender;

        require(
            IERC1155(collection).balanceOf(address(this), id) >= value,
            "TrashBin: transfer to TrashBin failed."
        );

        require(
            value <= 100,
            "TrashBin: a maximum of 100 NFTs per transaction."
        );

        for (uint256 i = 0; i < value; i++) {
            _sellERC1155(collection, id);
        }

        (bool success, ) = (from).call{value: sellPrice}("");
        require(success, "TrashBin: sale to depositor failed.");

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4) {
        address collection = msg.sender;

        require(
            ids.length <= 100,
            "TrashBin: a maximum of 100 NFT ids per transaction."
        );

        for (uint256 i = 0; i < ids.length; i++) {

            require(
                IERC1155(collection).balanceOf(address(this), ids[i]) >= values[i],
                "TrashBin: transfer to TrashBin failed."
            );

            require(
                values[i] <= 100,
                "TrashBin: a maximum of 100 NFTs per id."
            );

            for (uint256 j = 0; j < values[i]; j++) {
                _sellERC1155(collection, ids[i]);
            }
        }

        (bool success, ) = (from).call{value: (sellPrice * ids.length)}("");
        require(success, "TrashBin: sale to depositor failed.");

        return this.onERC1155BatchReceived.selector;
    }

    //////////////////////
    //Ownership Function//
    //////////////////////

    function transferOwnership(address newOwner) public virtual override onlyOwnerOrHashesDAO {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /////////////////////////////
    //ERC165 Interface Function//
    /////////////////////////////

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        if (
            (interfaceId == type(Ownable).interfaceId) ||
            (interfaceId == type(Pausable).interfaceId) ||
            (interfaceId == type(IERC721Receiver).interfaceId) ||
            (interfaceId == type(IERC1155Receiver).interfaceId) ||
            (interfaceId == type(ReentrancyGuard).interfaceId)
        ) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governanceCap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IHashesDAO {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint128);

    function queue(uint128 _proposalId) external;

    function execute(uint128 _proposalId) external payable;

    function cancel(uint128 _proposalId) external;

    function castVote(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature
    ) external;

    function castVoteBySig(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature,
        bytes memory _signature
    ) external;

    function veto(uint128 _proposalId, bytes[] memory _signatures) external;

    function deactivateAuthorities(bytes[] memory _signatures, address[] memory _authorities) external;

    function getActions(uint128 _proposalId) external view;

    function getAuthorityStatus(address _authority) external view returns (bool);

    function getReceipt(uint128 _proposalId, address _voter) external view returns (Receipt memory);

    function getProposal(uint128 _proposalId) external view;

    function getIsQueuedTransaction(bytes32 _txHash) external view returns (bool);

    function getProposalCount() external view returns (uint128);

    function getLatestProposalId(address _proposer) external view returns (uint128);

    function state(uint128 _proposalId) external view returns (ProposalState);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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