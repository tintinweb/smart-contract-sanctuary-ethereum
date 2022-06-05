// Froggy Friends by Fonzy & Mayan (www.froggyfriendsnft.com) Ribbit Prime

//[email protected]@@@@........................
//.......................%@@@@@@@@@*[email protected]@@@#///(@@@@@...................
//[email protected]@@&(//(//(/(@@@.........&@@////////////@@@.................
//[email protected]@@//////////////@@@@@@@@@@@@/////@@@@/////@@@..............
//..................%@@/////@@@@@(////////////////////%@@@@/////#@@...............
//[email protected]@%//////@@@#///////////////////////////////@@@...............
//[email protected]@@/////////////////////////////////////////@@@@..............
//[email protected]@(///////////////(///////////////(////////////@@@............
//...............*@@/(///////////////&@@@@@@(//(@@@@@@/////////////#@@............
//[email protected]@////////////////////////(%&&%(///////////////////@@@...........
//[email protected]@@/////////////////////////////////////////////////&@@...........
//[email protected]@(/////////////////////////////////////////////////@@#...........
//[email protected]@@////////////////////////////////////////////////@@@............
//[email protected]@@/////////////////////////////////////////////#@@/.............
//................&@@@//////////////////////////////////////////@@@...............
//..................*@@@%////////////////////////////////////@@@@.................
//[email protected]@@@///////////////////////////////////////(@@@..................
//............%@@@////////////////............/////////////////@@@................
//..........%@@#/////////////..................... (/////////////@@@..............
//[email protected]@@////////////............................////////////@@@.............
//[email protected]@(///////(@@@................................(@@&///////&@@............
//[email protected]@////////@@@[email protected]@@///////@@@...........
//[email protected]@@///////@@@[email protected]@///////@@%..........
//.....(@@///////@@@[email protected]@/////(/@@..........

// Development help from Lexi

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IErc20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

interface IErc721 {
    function balanceOf(address owner) external view returns (uint256);
}

contract RibbitItem is Context, ERC165, IERC1155, IERC1155MetadataURI, Ownable {
    using Address for address;

    // Variables
    string public name;
    string public symbol;
    string private baseUrl;
    uint256 collabIdCounter = 1;
    uint256 idCounter;

    // Interfaces
    IErc20 ribbit;
    IErc721 froggyFriends;

    // Maps
    mapping(uint256 => uint256) price; 											// Item ID to price
    mapping(uint256 => uint256) percent; 										// Item ID to boost percentage
    mapping(uint256 => uint256) supply; 										// Item ID to supply
    mapping(uint256 => bool) boost; 											// Item ID to boost status (true if boost)
    mapping(uint256 => uint256) minted; 										// Item ID to minted supply
    mapping(uint256 => bool) onSale; 											// Item ID to sale status (true if on sale)
    mapping(uint256 => uint256) walletLimit; 									// Item ID to mint cap per wallet
    mapping(uint256 => address[]) holders; 										// Item ID to list of holder addresses
    mapping(uint256 => address) collabAddresses; 								// Item ID to collab account
    mapping(address => bool) approvedBurnAddress; 								// Address to burn state (true if approved)
    mapping(uint256 => mapping(address => uint256)) private _balances; 			// Token ID to map of address to balance
    mapping(address => mapping(address => bool)) private _operatorApprovals;    // Address to map of address to approval status (true if approved)
    mapping(uint256 => mapping(address => uint256)) private track; 				// Item ID to map of address to mint count
    mapping(address => mapping(uint256 => uint256)) private mintLimitCounter;	// Address to map of item ID to mint count

    constructor(string memory _name, string memory _symbol, string memory _baseUrl, address _ribbitAddress, address _froggyAddress) {
        name = _name;
        symbol = _symbol;
        baseUrl = _baseUrl;
        ribbit = IErc20(_ribbitAddress);
        froggyFriends = IErc721(_froggyAddress);

        // Ribbit Items
        listItem(1,       200000 * 10**18, 6, true, 1); 		 // Golden Lily Pad
        listFriend(2, 5, 	 700 * 10**18, 200, true, true, 1);  // Rabbit Friend
        listFriend(3, 10,   1800 * 10**18, 150, true, true, 1);  // Bear Friend
        listFriend(4, 15,   5000 * 10**18, 75, true, true, 1);   // Red Panda Friend
        listFriend(5, 20,  10000 * 10**18, 10, true, true, 1);   // Cat Friend
        listFriend(6, 30, 100000 * 10**18, 6, true, true, 1);    // Unicorn Friend
        listFriend(7, 30, 300000 * 10**18, 1, true, true, 1);    // Golden Tiger Friend

        listCollabFriend(8, 10, 	700 * 10**18, 5, true, true, 1, 0xba033D82c64DD514B184e2d1405cD395dfE6e706); // Bao Society Friend
        listCollabFriend(9, 10, 	700 * 10**18, 5, true, true, 1, 0x928f072C009727FbAd81bBF3aAa885f9fEa65fcf); // Roo Troop Friend
        listCollabFriend(10, 5, 	700 * 10**18, 5, true, true, 1, 0x67421C8622F8E38Fe9868b4636b8dC855347d570); // Squishiverse Friend
        listCollabFriend(11, 5, 	700 * 10**18, 5, true, true, 1, 0x1a2F71468F656E97c2F86541E57189F59951efe7); // CryptoMories Friend
        listCollabFriend(12, 10,   1000 * 10**18, 2, true, true, 1, 0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83); // Kaiju Kings Friend

		listItem(13, 500 * 10**18, 10, true, 1); // froggy friend raffle
		listItem(14, 500 * 10**18, 10, true, 1); // froggy friend raffle
		listItem(15, 500 * 10**18, 10, true, 1); // froggy friend raffle

		listItem(16, 500 * 10**18, 1, true, 1); // froggy friend nft
        listItem(17, 500 * 10**18, 1, true, 1); // froggy friend nft
        listItem(18, 500 * 10**18, 1, true, 1); // froggy friend nft

        // Reserve golden lily pad and unicorn for froggy milestones raffle
        _mint(owner(), 1, 1, "");
        _mint(owner(), 6, 1, "");
    }

    /// @notice Bundle buy Ribbit Items
    /// @param ids list of ribbit item ids to buy
    /// @param amount list of ribbit item amounts
    function bundleBuy(uint256[] memory ids, uint256[] memory amount) public {
        require(ids.length == amount.length, "Ribbit item ID missing");
        for (uint256 i; i < ids.length; i++) {
            require(ids[i] > 0, "Ribbit item ID must not be zero");
            require(price[ids[i]] > 0, "Ribbit item price not set");
            uint256 saleAmount = amount[i] * price[ids[i]];
            require(ribbit.balanceOf(msg.sender) >= saleAmount, "Insufficient funds for purchase");
            require(onSale[ids[i]] == true, "Ribbit item not on sale");
            require(supply[ids[i]] > 0, "Ribbit item supply not set");
            require(walletLimit[ids[i]] > 0, "Ribbit item wallet limit not set");
            require(minted[ids[i]] + amount[i] <= supply[ids[i]], "Ribbit item supply exceeded");
            require(mintLimitCounter[msg.sender][ids[i]] + amount[i] <= walletLimit[ids[i]], "Ribbit item wallet limit exceeded");
            mintLimitCounter[msg.sender][ids[i]] += amount[i];
            if (track[ids[i]][msg.sender] < 1) {
                holders[ids[i]].push(msg.sender);
                track[ids[i]][msg.sender] = 1;
            }
            ribbit.transferFrom(msg.sender, address(this), saleAmount);
            minted[ids[i]] += amount[i];
            _mint(msg.sender, ids[i], amount[i], "");
        }
    }

    /// @notice Buy collab friend
    /// @param id the ribbit item id
    /// @param amount the amount of the ribbit item
    /// @param collabId the collab id of the ribbit item
    function collabBuy(uint256 id, uint256 amount, uint256 collabId) public {
        IErc721 collabNFT = IErc721(collabAddresses[collabId]);
        require(collabNFT.balanceOf(msg.sender) > 0, "Collab nft not owned");
        require(froggyFriends.balanceOf(msg.sender) > 0, "Froggy friend not owned");
        require(id > 0, "Ribbit item ID must not be zero");
        require(price[id] > 0, "Ribbit item price not set");
        uint256 saleAmount = amount * price[id];
        require(ribbit.balanceOf(msg.sender) >= saleAmount, "Insufficient funds for purchase");
        require(onSale[id] == true, "Ribbit item not on sale");
        require(supply[id] > 0, "Ribbit item supply not set");
        require(walletLimit[id] > 0, "Ribbit item wallet limit not set");
        require(minted[id] + amount <= supply[id], "Ribbit item supply exceeded");
        require(mintLimitCounter[msg.sender][id] + amount <= walletLimit[id], "Ribbit item wallet limit exceeded");
        mintLimitCounter[msg.sender][id] += amount;
        if (track[id][msg.sender] < 1) {
            holders[id].push(msg.sender);
            track[id][msg.sender] = 1;
        }
        ribbit.transferFrom(msg.sender, address(this), saleAmount);
        minted[id] += amount;
        _mint(msg.sender, id, amount, "");
    }

    /// @notice list friend ribbit item
    /// @param id the ribbit item id
    /// @param _percent the friend boost percentage
    /// @param _price the friend price
    /// @param _supply the friend supply
    /// @param _boost the friend boost status (true if is a boost)
    /// @param _onSale the friend sale status (true if is on sale)
    /// @param _walletLimit the friend wallet limit
    function listFriend(uint256 id, uint256 _percent, uint256 _price, uint256 _supply, bool _boost, bool _onSale, uint256 _walletLimit) public onlyOwner {
        require(id > idCounter, "Ribbit item ID exists");
        price[id] = _price;
        percent[id] = _percent;
        supply[id] = _supply;
        boost[id] = _boost;
        onSale[id] = _onSale;
        walletLimit[id] = _walletLimit;
        idCounter++;
    }

    /// @notice list collab friend item
    /// @param id the ribbit item id
    /// @param _percent the collab friend boost percentage
    /// @param _price the collab friend price
    /// @param _supply the collab friend supply
    /// @param _boost the collab friend boost status (true if is a boost)
    /// @param _onSale the collab friend sale status (true if is on sale)
    /// @param _walletLimit the collab friend wallet limit
    /// @param _collabAddress the collab NFT address
    function listCollabFriend(uint256 id, uint256 _percent, uint256 _price, uint256 _supply, bool _boost, bool _onSale, uint256 _walletLimit, address _collabAddress) public onlyOwner {
        require(id > idCounter, "Ribbit item ID exists");
        price[id] = _price;
        percent[id] = _percent;
        supply[id] = _supply;
        boost[id] = _boost;
        onSale[id] = _onSale;
        walletLimit[id] = _walletLimit;
        collabAddresses[collabIdCounter] = _collabAddress;
        collabIdCounter++;
        idCounter++;
    }

    /// @notice list ribbit item
    /// @param id the ribbit item id
    /// @param _price the ribbit item price
    /// @param _supply the ribbit item supply
    /// @param _onSale the ribbit item sale status (true if is on sale)
    /// @param _walletLimit the ribbit item wallet limit
    function listItem(uint256 id, uint256 _price, uint256 _supply, bool _onSale, uint256 _walletLimit) public onlyOwner {
        require(id > idCounter, "Ribbit item ID exists");
        price[id] = _price;
        supply[id] = _supply;
        onSale[id] = _onSale;
        walletLimit[id] = _walletLimit;
        idCounter++;
    }

    /// @notice sets the ribbit item price
    /// @param id the ribbit item id
    function setPrice(uint256 id, uint256 _price) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        price[id] = _price;
    }

    /// @notice sets the ribbit item percent
    /// @param id the ribbit item id
    function setPercent(uint256 id, uint256 _percent) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        percent[id] = _percent;
    }

    /// @notice sets the ribbit item boost status (true if is boost)
    /// @param id the ribbit item id
    function setIsBoost(uint256 id, bool _isBoost) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        boost[id] = _isBoost;
    }

    /// @notice sets the ribbit item supply
    /// @param id the ribbit item id
    function setSupply(uint256 id, uint256 _supply) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        supply[id] = _supply;
    }

    /// @notice sets ribbit item sale status
    /// @param id the ribbit item id
    /// @param _onSale the ribbit item sale status (true if is on sale)
    function setOnSale(uint256 id, bool _onSale) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        onSale[id] = _onSale;
    }

    /// @notice sets ribbit item wallet limit
    /// @param id the ribbit item id
    /// @param _walletLimit the new wallet limit
    function setWalletLimit(uint256 id, uint256 _walletLimit) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        walletLimit[id] = _walletLimit;
    }

    /// @notice sets collab friend address
    /// @param collabId the collab friend ribbit item id
    /// @param _collabAddress the new collab friend address
    function setCollabAddress(uint256 collabId, address _collabAddress) public onlyOwner {
        require(collabId <= collabIdCounter, "ID does not exist");
        collabAddresses[collabId] = _collabAddress;
    }

    /// @notice sets address burn permissions
    /// @param add the address to update permissions for
    /// @param canBurn the permissions to grant (true if is approved for burning)
    function setApprovedBurnAddress(address add, bool canBurn) public onlyOwner {
        approvedBurnAddress[add] = canBurn;
    }

    /// @notice burns the amount of ribbit items specified
    /// @param from the address to burn the ribbit item from
    /// @param id the ribbit item id
    /// @param amount the amount of ribbit items to burn
    /// @dev burn function called by StakeFroggies.sol
    function burn(address from, uint256 id, uint256 amount) external {
        require(approvedBurnAddress[msg.sender] == true, "Address not approved for burning");
        _burn(from, id, amount);
    }

    /// @notice admin burns the entire ribbit item supply
    /// @param id the ribbit item id
    /// @dev only admin can burn the ribbit item supply
    /// @dev only use to burn temporary ribbit items
    function adminBurn(uint256 id) public onlyOwner {
        for (uint256 i; i < holders[id].length; i++) {
            _burn(holders[id][i], id, (balanceOf(holders[id][i], id)));
        }
    }

    /// @notice admin mint ribbit item to address
    /// @param account the address to mint the ribbit item to
    /// @param id the ribbit item id
    /// @param amount the amount of ribbit items
    function adminMint(address account, uint256 id, uint256 amount) public onlyOwner {
        require(minted[id] + amount <= supply[id], "Ribbit item supply exceeded");
        minted[id] += amount;
        _mint(account, id, amount, "");
    }

    /// @notice admin mints remaining ribbit items
    /// @param id the ribbit item id
    function adminMintAll(uint256 id) public onlyOwner {
        uint256 remaining = supply[id] - minted[id];
        require(minted[id] + remaining <= supply[id], "");
        require(remaining > 0, "Ribbit item supply reached");
        minted[id] += remaining;
        _mint(msg.sender, id, remaining, "");
    }

    /// @notice returns the ribbit item price by id
    /// @param id the ribbit item id
    function getPrice(uint256 id) public view returns (uint256) {
        return price[id];
    }

    /// @notice returns the ribbit item boost percentage
    /// @param id the ribbit item id
    /// @dev boostPercentage function called by StakeFroggies.sol
    function boostPercentage(uint256 id) public view returns (uint256) {
        return percent[id];
    }

	/// @notice returns the max supply of a ribbit item
    /// @param id the ribbit item id
    function maxSupply(uint256 id) public view returns (uint256) {
        return supply[id];
    }

	/// @notice returns the ribbit item boost status (true if is boost)
    /// @param id the ribbit item id
    /// @dev isBoost function called by StakeFroggies.sol
    function isBoost(uint256 id) public view returns (bool) {
        return boost[id];
    }

	/// @notice returns the minted supply of a ribbit item
    /// @param id the ribbit item id
    function mintedSupply(uint256 id) public view returns (uint256) {
        return minted[id];
    }

    /// @notice returns the ribbit item sale status (true if is on sale)
    /// @param id the ribbit item id
    function isOnSale(uint256 id) public view returns (bool) {
        return onSale[id];
    }

    /// @notice returns the ribbit item wallet limit
    /// @param id the ribbit item id
    function getWalletLimit(uint256 id) public view returns (uint256) {
        return walletLimit[id];
    }

	/// @notice returns ribbit item properties by id
    /// @param id the ribbit item id
    /// @return item properties
    function item(uint256 id) public view returns (uint256, uint256, uint256, bool, uint256, bool, uint256) {
        return (
            getPrice(id), 
            boostPercentage(id), 
            maxSupply(id), 
            isBoost(id), 
            mintedSupply(id), 
            isOnSale(id), 
            getWalletLimit(id)
        );
    }


	/// @notice returns the total number of ribbit items listed
    function totalListed() public view returns (uint256) {
        return idCounter;
    }

    /// @notice returns the number of collab friends listed
    function totalCollabs() public view returns (uint256) {
        return collabIdCounter;
    }

    /// @notice returns the collab address of a collab friend
    /// @param id the ribbit item id
    function collabAddress(uint256 id) public view returns (address) {
        return collabAddresses[id];
    }

	/// @notice returns the number of ribbit items an account owns
    /// @param account the address to check the balance of
    /// @param id the ribbit item id
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /// @notice returns ribbit item holders
    /// @param id the ribbit item id
    function itemHolders(uint256 id) public view returns (address[] memory) {
        return holders[id];
    }

    /// @notice sets the ribbit contract address
    /// @param account the ribbit address
    function setRibbitAddress(address account) public onlyOwner {
        ribbit = IErc20(account);
    }

    /// @notice sets the froggy friends contract address
    /// @param account the froggy friends address
    function setFroggyFriendsAddress(address account) public onlyOwner {
        froggyFriends = IErc721(account);
    }

    /// @notice withdraws ribbit balance from this contract to the admin account
    function withdrawRibbit() public onlyOwner {
        ribbit.transfer(msg.sender, ribbit.balanceOf(address(this)));
    }

    /// @dev uri fills the base url with the supplied item id
    /// @dev output format example if hosted on API https://api.froggyfriendsnft.com/item/{id}
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseUrl, Strings.toString(_tokenId)));
    }

    /// @notice sets the metadata base url
    /// @param _baseUrl the metadata base url for example 'https://api.froggyfriendsnft.com/item/'
    function setURI(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    /// @dev See {IERC1155-balanceOfBatch}.
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev See {IERC1155-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @dev See {IERC1155-isApprovedForAll}.
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /// @dev See {IERC1155-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not owner nor approved");

        _safeTransferFrom(from, to, id, amount, data);
        if (track[id][to] < 1) {
            holders[id].push(to);
            track[id][to] = 1;
        }

        if (balanceOf(from, id) == 0) {
            track[id][from] = 0;
            for (uint256 j; j < holders[id].length; j++) {
                if (holders[id][j] == from) {
                    holders[id][j] = holders[id][holders[id].length - 1];
                    holders[id].pop();
                    break;
                }
            }
        }
    }

    //// @dev See {IERC1155-safeBatchTransferFrom}.
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 i; i < ids.length; i++) {
            if (track[ids[i]][to] < 1) {
                holders[ids[i]].push(to);
                track[ids[i]][to] = 1;
            }

            if (balanceOf(from, ids[i]) == 0) {
                track[ids[i]][from] = 0;
                for (uint256 j; j < holders[ids[i]].length; j++) {
                    if (holders[ids[i]][j] == from) {
                        holders[ids[i]][j] = holders[ids[i]][holders[ids[i]].length - 1];
                        holders[ids[i]].pop();
                        break;
                    }
                }
            }
        }
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

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
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
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

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
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