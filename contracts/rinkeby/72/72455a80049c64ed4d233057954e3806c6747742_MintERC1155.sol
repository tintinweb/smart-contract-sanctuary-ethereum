// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";

contract MintERC1155 is ERC1155, Ownable, ERC1155Burnable {
    using Strings for uint256;
    ERC1155Burnable mintPassContract;
    IERC20 token;
    IERC1155 token1155;

    string name;
    string symbol;

    string baseURI;
    bool public paused;

    uint256 public cost = 1 * 10 ** 18;
    uint256 public totalPaid;

    uint256 private tokenId = 0;

    mapping(address => uint256[]) adrToIds;

    mapping(uint256 => Item) private items;

    struct wl {
        uint256 amount;
        uint256 cost;
    }

    mapping(address => uint256) public amountsNFT;
    mapping(address => uint256) public amountsNFTMinted;
    mapping(address => uint256) publicMinted;
    /*mapping(address => uint256[]) public idOfUser;*/

    mapping(uint256 => Admin) idToAdmin;
    mapping(address => uint256) adrToId;
    mapping(address => bool) isAdmin;
    uint256 public adminAmount;
    address[] private admins;

    struct Admin {
        uint256 id;
        address user;
        bool isAdmin;
    }

    uint256 public nftAmountPerUser;

    uint256 public maxAmount = 7500;
    uint256 public currentAmount;

    struct Item {
        uint256 id;
        address creator;
        uint256 quantity;
        address holder;
    }

    struct drop {
        uint256 totalSupply;
        uint256 minted;
        uint256 privateStartTime;
        uint256 privateDuration;
        uint256 publicStartTime;
        uint256 publicDuration;
        uint cost;
    }

    mapping(uint256 => drop) idToDrop;
    uint256 public totalDrop;

    uint256 nextDropStartTime;
    uint256 nextDropDuration;
    uint256 nextDropAmount;

    constructor(
        uint256 cost_,
        string memory uri_,
        uint256 nftAmountPerUser_,
        string memory name_,
        string memory symbol_,
        address mintPassAddress,
        address tokenAddress
    ) ERC1155(uri_) {
        cost = cost_;
        baseURI = uri_;
        paused = true;
        nftAmountPerUser = nftAmountPerUser_;
        name = name_;
        symbol = symbol_;
        mintPassContract = ERC1155Burnable(mintPassAddress);
        token = IERC20(tokenAddress);
        token1155 = IERC1155(mintPassAddress);
    }

    function changeTokenContract(address newToken) external onlyOwner {
        token = IERC20(newToken);
    }

    function changeMintPassContract(address newTokenContract)
    external
    onlyOwner
    {
        mintPassContract = ERC1155Burnable(newTokenContract);
        token1155 = ERC1155(newTokenContract);
    }

    function freeClaimPass(uint256 amount) external {
        require(!paused, "mint is paused");

        require(currentAmount + amount <= maxAmount, "Amount is exceeded");

        require(
            (block.timestamp > idToDrop[totalDrop].privateStartTime && block.timestamp < idToDrop[totalDrop].privateStartTime + idToDrop[totalDrop].privateDuration)
            || (block.timestamp > idToDrop[totalDrop].publicStartTime && block.timestamp < idToDrop[totalDrop].publicStartTime + idToDrop[totalDrop].publicDuration),
            "Not time to mint"
        );
        require(
            idToDrop[totalDrop].minted + amount <=
            idToDrop[totalDrop].totalSupply,
            "Supply is exceeded"
        );

        address user = msg.sender;

        require(
            token1155.balanceOf(user, 1) > 0,
            "You don't have freeClaimPass key"
        );

        mintPassContract.burn(msg.sender, 1, amount);

        _mint(msg.sender, tokenId, amount, "");
        currentAmount += amount;
        amountsNFT[msg.sender] += amount;
        idToDrop[totalDrop].minted += amount;
        //amountsNFTMinted[msg.sender] += amount;
        items[tokenId] = Item(tokenId, msg.sender, amount, msg.sender);
    }

    function mintPass(uint256 amount) external {
        require(!paused, "mint is paused");

        require(currentAmount + amount <= maxAmount);

        require(
            (block.timestamp > idToDrop[totalDrop].privateStartTime && block.timestamp < idToDrop[totalDrop].privateStartTime + idToDrop[totalDrop].privateDuration)
            || (block.timestamp > idToDrop[totalDrop].publicStartTime && block.timestamp < idToDrop[totalDrop].publicStartTime + idToDrop[totalDrop].publicDuration),
            "Not time to mint"
        );
        require(
            idToDrop[totalDrop].minted + amount <=
            idToDrop[totalDrop].totalSupply,
            "Supply is exceeded"
        );

        address user = msg.sender;

        require(
            token1155.balanceOf(user, 0) > 0,
            "You don't have mintPass key"
        );

        mintPassContract.burn(msg.sender, 0, amount);
        token.transferFrom(
            msg.sender,
            address(this),
            (cost * amount * 80) / 100
        );

        _mint(msg.sender, tokenId, amount, "");
        currentAmount += amount;
        amountsNFT[msg.sender] += amount;
        //amountsNFTMinted[msg.sender] += amount;
        idToDrop[totalDrop].minted += amount;
        items[tokenId] = Item(tokenId, msg.sender, amount, msg.sender);
    }

    function mint(address to, uint256 amount) external payable {
        require(!paused, "mint is paused");

        require(currentAmount + amount <= maxAmount);

        require(
            publicMinted[msg.sender] + amount <= nftAmountPerUser,
            "NFT per user is exceeded"
        );
        require(
            block.timestamp > idToDrop[totalDrop].publicStartTime &&
            block.timestamp < idToDrop[totalDrop].publicStartTime + idToDrop[totalDrop].publicDuration,
            "Not time to mint"
        );
        require(
            idToDrop[totalDrop].minted + amount <=
            idToDrop[totalDrop].totalSupply,
            "Supply is exceeded"
        );

        token.transferFrom(
            msg.sender,
            address(this),
            idToDrop[totalDrop].cost * amount
        );

        _mint(to, tokenId, amount, "");
        currentAmount += amount;
        amountsNFT[to] += amount;
        amountsNFTMinted[msg.sender] += amount;
        publicMinted[msg.sender] += amount;
        idToDrop[totalDrop].minted += amount;
        items[tokenId] = Item(tokenId, msg.sender, amount, msg.sender);
    }

    function makeDrop(
        uint256 amount,
        uint256 privateStartTime,
        uint256 privateDuration,
        uint256 publicStartTime,
        uint256 publicDuration,
        uint cost_
    ) external onlyOwner {
        totalDrop++;
        idToDrop[totalDrop] = drop(amount, 0, privateStartTime, privateDuration, publicStartTime, publicDuration, cost_);
        cost = cost_;
    }

    function nameCollection() external view returns (string memory) {
        return name;
    }

    function symbolCollection() external view returns (string memory) {
        return symbol;
    }

    function setNameCollection(string memory name_) external onlyOwner {
        name = name_;
    }

    function changePauseStatus() external onlyOwner {
        paused = !paused;
    }

    function changeMaxAmount(uint256 newMaxAMount) external onlyOwner {
        require(newMaxAMount >= currentAmount);
        maxAmount = newMaxAMount;
    }

    function changeNftAmountPerUser(uint256 newAmount) external onlyOwner {
        nftAmountPerUser = newAmount;
    }

    function checkUserIds() external view returns (uint256[] memory) {
        return adrToIds[msg.sender];
    }

    function checkUserMintedAmount() external view returns (uint256) {
        return amountsNFTMinted[msg.sender];
    }

    function checkUserActualAmount() external view returns (uint256) {
        return amountsNFT[msg.sender];
    }

    function checkCurrentDropSupply() external view returns (uint256) {
        return idToDrop[totalDrop].totalSupply;
    }

    function _ownerOf(uint256 _tokenId) internal view returns (bool) {
        return balanceOf(msg.sender, _tokenId) != 0;
    }

    function isInArray(uint256[] memory Ids, uint256 id)
    internal
    pure
    returns (bool)
    {
        for (uint256 i; i < Ids.length; i++) {
            if (Ids[i] == id) {
                return true;
            }
        }
        return false;
    }

    function uri(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_tokenId == tokenId);
        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return
        bytes(baseURI).length > 0
        ? string(
            abi.encodePacked(baseURI)
        )
        : "";
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable {
        //require(blacklist[msg.sender] == false, "User blacklisted");
        for (uint256 i; i < amounts.length; i++) {
            require(amounts[i] == 1, "amount has to be 1");
        }
        require(from == msg.sender, "not allowance");

        _safeBatchTransferFrom(from, to, ids, amounts, "");
        //adrToIds[msg.sender]
        for (uint256 i; i < adrToIds[msg.sender].length; i++) {
            for (uint256 j; j < ids.length; j++) {
                if (adrToIds[msg.sender][i] == ids[j]) {
                    adrToIds[to].push(ids[j]);
                    remove(i, msg.sender);
                    items[ids[j]].holder = to;
                }
            }
        }
        amountsNFT[msg.sender] -= ids.length;
        amountsNFT[to] += ids.length;
    }

    function transfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external payable {
        require(from == msg.sender, "not allowance");
        require(amount == 1, "amount has to be 1");

        _safeTransferFrom(from, to, id, amount, "");
        items[id].holder = to;

        for (uint256 i; i < adrToIds[msg.sender].length; i++) {
            if (adrToIds[msg.sender][i] == id) {
                adrToIds[to].push(id);
                remove(i, msg.sender);
            }
        }
        amountsNFT[msg.sender]--;
        amountsNFT[to]++;
    }

    function remove(uint256 index, address user)
    internal
    returns (uint256[] memory)
    {
        for (uint256 i = index; i < adrToIds[user].length - 1; i++) {
            adrToIds[user][i] = adrToIds[user][i + 1];
        }
        delete adrToIds[user][adrToIds[user].length - 1];
        adrToIds[user].pop();
        return adrToIds[user];
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {}

    function isInArrayMarket(address[] memory markets, address adr)
    internal
    pure
    returns (bool)
    {
        for (uint256 i; i < markets.length; i++) {
            if (markets[i] == adr) {
                return true;
            }
        }
        return false;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {

        _safeTransferFrom(from, to, id, amount, data);
        adrToIds[to].push(id);
        for (uint256 i; i < adrToIds[from].length; i++) {
            if (adrToIds[from][i] == id) {
                remove(i, from);
            }
        }
        items[id].holder = to;
        amountsNFT[from]--;
        amountsNFT[to]++;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function addAdmin(address admin) external onlyOwner {

        require(isAdmin[admin] != true, "Already admin");
        adminAmount++;
        idToAdmin[adminAmount] = Admin(adminAmount, admin, true);
        adrToId[admin] = adminAmount;
        admins.push(admin);
        isAdmin[admin] = true;
    }

    function showAdmins() external view returns (address[] memory) {
        return (admins);
    }

    function deleteAdmin(address admin) external onlyOwner {
        require(
            idToAdmin[adrToId[admin]].isAdmin == true,
            "User is not in admin list"
        );
        idToAdmin[adrToId[admin]].isAdmin = false;
        for (uint256 i; i < admins.length; i++) {
            if (admins[i] == idToAdmin[adrToId[admin]].user) {
                removeAdmin(i);
                break;
            }
        }
        adminAmount--;
        isAdmin[admin] = false;
    }

    function removeAdmin(uint256 index) internal returns (address[] memory) {

        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        delete admins[admins.length - 1];
        admins.pop();
        return admins;
    }

    function showItems(uint256 number) external view returns (Item memory) {
        require(items[number].id == tokenId);
        return items[number];
    }

    function checkDropInfo(uint256 number) external view returns (drop memory) {
        require(number <= totalDrop, "drop number doesn't exist");
        return idToDrop[number];
    }

    function availableNFTs()
    external
    view
    returns (uint256 amount, uint256 costForMint)
    {
        return (idToDrop[totalDrop].totalSupply - idToDrop[totalDrop].minted, cost);
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function withdraw() public onlyOwner returns (uint256) {
        uint256 withdrawable = token.balanceOf(address(this));
        require(withdrawable > 0, "withdraw: Nothing to withdraw");
        require(token.transfer(
                getOwner(),
                token.balanceOf(address(this))
            ), "Withdraw: Can't withdraw!");
        return withdrawable;
    }
}