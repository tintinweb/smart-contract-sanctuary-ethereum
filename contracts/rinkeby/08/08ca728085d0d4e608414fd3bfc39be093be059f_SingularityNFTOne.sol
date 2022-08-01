// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";

struct SingularityItem {
    uint256 id;
    uint256 maxSupply;
    uint256 mintStart;
}


error MinterNotHuman(address sender, address origin);
error MintNotStarted(uint256 startTime,  uint256 currentTime);
error MaxSupplyReached(uint256 available, uint256 desired);

contract SingularityNFTOne is ERC1155, ERC1155Supply, Ownable {
    string public constant name = "123";
    string public constant symbol = "\u2B58";

    mapping(uint256 => SingularityItem) private _items;
    mapping(address => mapping(uint256 => uint256)) private _mintsPerWallet;
    
    
    mapping(uint256 => bool) public WhitelistStatus;


    mapping(address => mapping(uint256 => uint256)) public _whitelistedWalletAmounts;
    mapping(address => bool) public BlaclistedWallets;

    constructor(string memory uri) ERC1155(uri) { //https://incarnation.singularityblockchain.com/metadata/{id}.json
    }

    function setUri(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }

    function addItem(uint256 id, uint256 maxSupply, uint256 mintStart) external onlyOwner {
        _items[id] = SingularityItem(id, maxSupply, mintStart);
    }

    function getItem(uint256 id) public view returns(SingularityItem memory) {
        return _items[id];
    }

    function getItems(uint256[] calldata ids) external view returns(SingularityItem[] memory) {
        uint256 idsLength = ids.length;
        SingularityItem[] memory items = new SingularityItem[](idsLength);

        for (uint256 i = 0; i < idsLength; ++i) {
            items[i] = getItem(ids[i]);
        }

        return items;
    }

    function mintsPerWallet(address addr, uint256 id) public view returns(uint256) {
        return _mintsPerWallet[addr][id];
    }


    function mint(uint256 id) external {
        uint256 amount;
        require(BlaclistedWallets[msg.sender] == false,"Your wallet is blacklisted"); //if a wallet is blacklisted it cant mint no matter what
        
        if (msg.sender != tx.origin) {
            revert MinterNotHuman(msg.sender, tx.origin); //if msg.sender and tx.origin is not the same (there is a contract that tries to intereact with nft contract revert it )
        }
        
        if(WhitelistStatus[id]){ 
            amount = _whitelistedWalletAmounts[msg.sender][id]; 
            require(amount > 0,"You are not whitelisted or you already have minted."); //if whitelist is on only whitelisted wallet can mint the amount which is predetermined again..
            _whitelistedWalletAmounts[msg.sender][id] = 0; //remove that wallet from whitelist
        }
        else{
            require(_mintsPerWallet[msg.sender][id]<1,"You have minted more than 1 NFT"); //if whitelist is off then every wallet can mint max of 1 nft with specified id
            amount = 1;
        }

        SingularityItem memory item = _items[id];
        if (item.mintStart > block.timestamp) {
            revert MintNotStarted(item.mintStart, block.timestamp); 
        }

        if (totalSupply(id) + amount > item.maxSupply) {
            revert MaxSupplyReached(item.maxSupply - totalSupply(id), amount);
        }

        _mintsPerWallet[msg.sender][id] = amount;
        _mint(msg.sender, id, amount, "");
    }

    function ownerMint(uint256 id, address[] calldata recipients, uint256 amount) external onlyOwner {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength != 0 && amount != 0);

        SingularityItem memory item = _items[id];

        if (totalSupply(id) + recipientsLength * amount > item.maxSupply) {
            revert MaxSupplyReached(item.maxSupply - totalSupply(id), recipientsLength * amount);
        }

        for (uint256 i = 0; i < recipientsLength; ++i) {
            _mint(recipients[i], id, amount, "");
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    function addToWhitelistMultipleAdress (address[] memory users, uint[] memory amount, uint id) external onlyOwner  {
        for (uint i = 0; i < users.length; i++) {
            _whitelistedWalletAmounts[users[i]][id] = amount[i];
        }
    }

    function ChangeWhitelistStatusOfId(uint256 _id ,bool _status) external onlyOwner{
        WhitelistStatus[_id] = _status;
    }

    function addToBlacklistMultipleAdress (address[] memory users, bool[] memory status) external onlyOwner  {
        for (uint i = 0; i < users.length; i++) {
            BlaclistedWallets[users[i]] =  status[i];
        }
    }

}