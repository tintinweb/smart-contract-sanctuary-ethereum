// SPDX-License-Identifier: CC-BY-NC-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./ShellNFT.sol";

// import "hardhat/console.sol";

contract SeaCoin is IERC20, IERC20Metadata, Ownable {
    using ECDSA for bytes32;

    string private _name;
    string private _symbol;
    // The max number of coins.
    uint24 private _maxSupply;
    // The current number of coins.
    // a uint24 is 16,777,215.
    uint24 private _totalSupply;
    // the address that can sign mint requests.
    address private _treasury;
    // the address of the NFT interface contract.
    address private _nftInterface;

    // erc20 access control
    mapping(address => mapping(address => uint256)) private _allowances;

    // Mapping from token ID to approved address NFT ERC-721
    mapping(uint24 => address) private _nftApprovals;

    // erc721 access control
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // NFTs owned by a wallet
    mapping(address => uint24[]) private _OwnerToLiquidCoinMap;

    // NFTs Frozen by a wallet
    mapping(address => uint24[]) private _OwnerToFrozenNftMap;

    // Find the owner of a specific NFT
    mapping(uint24 => address) private _LiquidNftToOwnerMap;

    // Find the owner of a specific NFT
    mapping(uint24 => address) private _FrozenNftsToOwnerMap;

    // represents if the address is denylisted with the contract. denylist takes priority before all other permissions
    mapping(address => bool) private _denylist;
    event AddedToDenylist(address[] addrs);
    event RemovedFromDenylist(address[] addrs);
    event UpdatedTreasury(address owner);
    // custom events
    event FreezeNft(address arbiter, uint24 nft_index);
    event UnfreezeNft(address arbiter, uint24 nft_index);

    constructor(string memory name_, string memory symbol_) {
        // Art Flake Coin
        _name = name_;

        // Globally unique trading symbol
        _symbol = symbol_;

        // 1 million tokens.
        _maxSupply = 1000000;

        // We start off without a premine, no coins minted.
        _totalSupply = 0;

        // The owner can sign mint requests to start:
        _treasury = owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * ERC20
     *
     * @dev Must return 0, NFTs cannot be sub-devided.
     *
     * Flake are strictly whole.
     *
     */
    function decimals() public view virtual override returns (uint8) {
        // Not sub-devideable, only whole tokens.
        return 0;
    }

    /**
     * @dev See {IERC20-totalSupply} - number of coins minted.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Only show number minted.
        return _totalSupply;
    }

    /**
     * @dev Display the maximum that can be minted.
     */
    function maxSupply() public view virtual returns (uint256) {
        // Show how many can be minted.
        return _maxSupply;
    }

    /**
     * ERC20
     *
     * @dev See {IERC20-balanceOf}.
     *
     * NOTE: Returns the liquid coin blance.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        // Return only liquid balance.
        return _OwnerToLiquidCoinMap[owner].length;
    }

    /**
     * ERC20
     *
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        // _transfer returns false if _balance change is different from amount
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * ERC20
     *
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * ERC20
     *
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint24`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * ERC20
     *
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address owner,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (owner != _msgSender()) {
            uint256 currentAllowance = allowance(owner, _msgSender());
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: insufficient allowance");
                unchecked {
                    _approve(owner, _msgSender(), currentAllowance - amount);
                }
            }
        }
        _transfer(owner, recipient, amount);
        return true;
    }

    /**
     * ERC20
     *
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }

    /**
     * ERC20
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * - `subtractedValue` must be a postive number.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * Flake Specific, not ERC721
     *
     * @dev Get list of frozen NFTs based on owner.
     *
     * Requirements:
     *
     * - `owner` must the address of the owner you want to lookup.
     */
    function getLiquidByOwner(address owner) public view virtual returns (uint24[] memory) {
        return _OwnerToLiquidCoinMap[owner];
    }

    /**
     * Flake Specific, not ERC721
     *
     * @dev Get list of Liquid NFTs based on the owner.
     *
     * Requirements:
     *
     * - `owner` must the address of the owner you want to lookup.
     */
    function getFrozenByOwner(address owner) public view virtual returns (uint24[] memory) {
        return _OwnerToFrozenNftMap[owner];
    }

    /****** ERC-721 COMPATIBILITY *******/

    /**
     * ERC-721
     *
     * @dev Returns the number of nft's in ``owner``'s account.
     *
     * NOTE: combines liquid and frozen token count
     */
    function balanceOfNft(address owner) public view virtual returns (uint256) {
        // Both frozen and unfrozen is the NFT collection for this account.
        // Both lists are added together for getNftsByOwner() - this is consistant.
        return _OwnerToLiquidCoinMap[owner].length + _OwnerToFrozenNftMap[owner].length;
    }

    /**
     * ERC-721
     *
     * @dev Get list of NFTs based on the owner.
     *
     * Requirements:
     *
     * - `owner` must the address of the owner you want to lookup.
     */
    function getNftsByOwner(address owner) public view virtual returns (uint24[] memory) {
        uint256 liquidLength = _OwnerToLiquidCoinMap[owner].length;
        uint256 frozenLength = _OwnerToFrozenNftMap[owner].length;
        uint24[] memory ownership = new uint24[](liquidLength + frozenLength);
        // check both lists to see if the user owns it:
        for (uint256 i = 0; i < liquidLength; i++) {
            ownership[i] = _OwnerToLiquidCoinMap[owner][i];
        }
        for (uint256 i = 0; i < frozenLength; i++) {
            ownership[i + liquidLength] = _OwnerToFrozenNftMap[owner][i];
        }
        return ownership;
    }

    /**
     * ERC-721
     *
     * @dev Get the owner address based on the nft index
     *
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function getOwnerbyNft(uint24 nft_index) public view virtual returns (address) {
        // require(nft_index <= _maxSupply, "ERC721: owner query for nonexistent token");
        if (isLiquid(nft_index)) {
            // Liquid coin
            return _LiquidNftToOwnerMap[nft_index];
        } else {
            // Frozen as stricly a flake NFT
            return _FrozenNftsToOwnerMap[nft_index];
            // if not in Frozen map then address(0) is returned.
        }
    }

    /**
     * @dev Gets the NFT status as a liquid or frozen solid.
     *
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function isFrozen(uint24 nft_index) public view virtual returns (bool) {
        // Find if an NFT cannot be used an ERC20
        return _FrozenNftsToOwnerMap[nft_index] != address(0);
    }

    /**
     * @dev Gets the NFT status as a liquid or frozen solid.
     *
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function isLiquid(uint24 nft_index) public view virtual returns (bool) {
        // Find if an NFT cannot be used an ERC20
        return _LiquidNftToOwnerMap[nft_index] != address(0);
    }

    /**
     * @dev allow the owner to freeze their NFT so it cannot be used as an ERC20
     *
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to freeze.
     */

    function freezeNft(uint24 nft_index) public virtual returns (bool) {
        return _freeze(_msgSender(), nft_index);
    }

    // passthrough for ERC-721 proxy
    function _freeze(address owner, uint24 nft_index) internal virtual returns (bool) {
        // This is an ERC20 balance change, check OFAC.
        _beforeTokenTransfer(owner, owner, 1);
        require(_LiquidNftToOwnerMap[nft_index] == owner, "You must own the NFT and it cannot be Frozen.");
        // Remove from the coin ledger:
        if (_removeCoin(owner, nft_index)) {
            // Add to the NFT ledger:
            require(_addNft(owner, nft_index));
            // Tell everybody about this huge success:
            emit FreezeNft(owner, nft_index);
            return true;
        }
        return false;
    }

    /**
     * @dev allow the owner to unlock so it can be used as an ERC20
     *
     * Requirements:
     *
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function unfreezeNft(uint24 nft_index) public virtual returns (bool) {
        return _unfreeze(_msgSender(), nft_index);
    }

    // passthrough for ERC-721 proxy
    function _unfreeze(address owner, uint24 nft_index) internal virtual returns (bool) {
        //This is an ERC20 balance change, check OFAC.
        _beforeTokenTransfer(owner, owner, 1);
        require(_FrozenNftsToOwnerMap[nft_index] == owner, "You must own the NFT and it cannot be Liquid.");
        // Remove from the coin ledger:
        if (_removeNft(owner, nft_index)) {
            // Add to the NFT ledger:
            require(_addCoin(owner, nft_index));
            // Tell everybody about this huge success:
            emit UnfreezeNft(owner, nft_index);
            return true;
        }

        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out coins,
     * this method cannot overide exsiting ownership
     *
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function _addCoin(address owner, uint24 nft_index) internal virtual returns (bool) {
        // Make sure we are minting within the range.
        require(nft_index <= _maxSupply, "Error: NFT index too large.");
        // Make sure this coin isn't owned.
        // This prevents replay attacks - the second message will have no effect.
        if (getOwnerbyNft(nft_index) == address(0)) {
            // Add it as liquid to the wallet.
            _OwnerToLiquidCoinMap[owner].push(nft_index);
            // Set owner
            _LiquidNftToOwnerMap[nft_index] = owner;
            return true;
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out tokens,
     * this method cannot overide exsiting ownership
     *
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function _addNft(address owner, uint24 nft_index) internal virtual returns (bool) {
        // Make sure we are minting within the range.
        require(nft_index <= _maxSupply, "Error: NFT index too large.");
        // Make sure this coin isn't owned.
        // This prevents replay attacks
        if (getOwnerbyNft(nft_index) == address(0)) {
            // Add it as a frozen NFT.
            _OwnerToFrozenNftMap[owner].push(nft_index);
            // set owner
            _FrozenNftsToOwnerMap[nft_index] = owner;
            // The user will have to unfreeze it if they want to use it as an ERC20
            return true;
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to remove coins,
     *
     * Requirements:
     *
     * - `owner` The wallet to remove coins.
     * - `reciver` The wallet of where the coins are going
     * - `amount` number of coins to move
     */
    function _transferCoin(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        // Move liquid from one owner to the other.
        uint24[] memory tokenIds = new uint24[](amount);
        for (uint256 idx = 0; idx < amount; idx++) {
            uint24 nft_index = _OwnerToLiquidCoinMap[from][_OwnerToLiquidCoinMap[from].length - 1];
            // Move the last token to the slot of the to-delete token
            // _OwnerToLiquidCoinMap[owner][idx] = nft_index;
            _OwnerToLiquidCoinMap[from].pop();
            // remove from the old user's wallet:
            _OwnerToLiquidCoinMap[to].push(nft_index);
            // Delete nft index to ownership lookup.
            _LiquidNftToOwnerMap[nft_index] = to;
            // emit event on nft contract
            tokenIds[idx] = nft_index;
        }
        ShellNFT(_nftInterface).transferEventProxy(from, to, tokenIds);
        return true;
    }

    /**
     * @dev allow the owner of the contract to remove coins,
     *
     * Requirements:
     *
     * - `owner` The wallet to remove NFT.
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function _removeCoin(address owner, uint24 nft_index) internal virtual returns (bool) {
        uint256 nftCount = _OwnerToLiquidCoinMap[owner].length;
        uint24 lastIndex = _OwnerToLiquidCoinMap[owner][nftCount - 1];
        // Check the liquid NFTs first:
        for (uint256 idx = 0; idx < nftCount; idx++) {
            if (_OwnerToLiquidCoinMap[owner][idx] == nft_index) {
                // Move the last token to the slot of the to-delete token
                _OwnerToLiquidCoinMap[owner][idx] = lastIndex;
                // remove from the old user's wallet:
                _OwnerToLiquidCoinMap[owner].pop();
                // Delete nft index to ownership lookup.
                delete _LiquidNftToOwnerMap[nft_index];
                // one and done.
                return true;
            }
        }
        return false;
    }

    /**
     * @dev allow the owner of the contract to hand out tokens,
     * this method cannot overide exsiting ownership
     *
     * Requirements:
     *
     * - `owner` The lucky wallet to get the new NFT.
     * - `nft_index` must the NFT index that you want to lookup.
     */
    function _removeNft(address owner, uint24 nft_index) internal virtual returns (bool) {
        uint256 nftCount = _OwnerToFrozenNftMap[owner].length;
        uint24 lastIndex = _OwnerToFrozenNftMap[owner][nftCount - 1];
        for (uint256 idx = 0; idx < nftCount; idx++) {
            if (_OwnerToFrozenNftMap[owner][idx] == nft_index) {
                // Move the last token to the slot of the to-delete token
                _OwnerToFrozenNftMap[owner][idx] = lastIndex;
                // remove from the old user's wallet:
                _OwnerToFrozenNftMap[owner].pop();
                // Delete nft's coin index to ownership lookup.
                delete _FrozenNftsToOwnerMap[nft_index];
                // Clear approvals from the previous owner
                delete _nftApprovals[nft_index];

                // one and done.
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `amount` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool retStatus) {
        // The zero address is also the empty case, and cannot be allowed.
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // check if the source and destination are allowed.
        _beforeTokenTransfer(sender, recipient, amount);

        // Do we have the liqudity?
        require(balanceOf(sender) >= amount, "ERC20: transfer amount exceeds balance");

        // change the list of NFTs and the balences.
        retStatus = _transferCoin(sender, recipient, amount);
        if (retStatus) {
            // Notify everyone of the transfer.
            emit Transfer(sender, recipient, amount);
        }
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `amount` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        // The zero address is also the empty case, and cannot be allowed.
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        // Make sure this is a valid amount to permit.
        if (amount > 0) {
            _allowances[owner][spender] = amount;
        } else {
            //If the approval is zero or less, remove the approval.
            delete _allowances[owner][spender];
        }
        // Notify observers of the chain.
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev change NFT ownership - Warning: Internal, needs access control before it.
     *
     * Requirements:
     *
     * - `oldOwner` The current owner, which will be changed
     * - `newOwner` The new NFT owner
     * - `nft_index` Which NFT to transfer
     */
    function _transferNftsFrozen(
        address oldOwner,
        address newOwner,
        uint24 nft_index
    ) internal virtual {
        // Always update the ownership map and freeze the NFT as it was treated as one.
        if (_FrozenNftsToOwnerMap[nft_index] == oldOwner) {
            // Remove the NFT from the oldOwner's frozen wallet:
            uint256 nftCount = _OwnerToFrozenNftMap[oldOwner].length;
            uint24 lastIndex = _OwnerToFrozenNftMap[oldOwner][nftCount - 1];
            for (uint256 idx = 0; idx < nftCount; idx++) {
                if (_OwnerToFrozenNftMap[oldOwner][idx] == nft_index) {
                    // Move the last token to the slot of the to-delete token
                    _OwnerToFrozenNftMap[oldOwner][idx] = lastIndex;
                    // remove from the old user's wallet:
                    _OwnerToFrozenNftMap[oldOwner].pop();
                    // Clear approvals from the previous owner
                    delete _nftApprovals[nft_index];
                    // Set the new owner.
                    _OwnerToFrozenNftMap[newOwner].push(nft_index);
                    _FrozenNftsToOwnerMap[nft_index] = newOwner;
                    // one and done.
                    break;
                }
            }
            // The NFT in quesiton might be in liquid from. That's fine, we'll put it on ice for transfer.
            // It needs to be put on ice so someone doesn't accidentally loose a work of art when doing
            // liquid transactions that overlap with art auctions.
        } else if (_LiquidNftToOwnerMap[nft_index] == oldOwner) {
            // Remove a liquid NFT from the oldOwner's wallet:
            if (_removeCoin(oldOwner, nft_index)) {
                // This interface always sends NFTs so it must arrive frozen:
                require(_addNft(newOwner, nft_index), "ERC721: Unable to add token");
            }
        } else {
            revert("ERC721: transfer from incorrect owner");
        }

        require(_FrozenNftsToOwnerMap[nft_index] == newOwner, "ERC721: Unable to transfer frozen token");
    }

    /**
     * @dev Approves the transfer of `nft_index`  by `sender`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `nft_index` cannot be the zero address.
     */
    function approveNft(
        address sender,
        address to,
        uint24 nft_index
    ) public virtual returns (address) {
        // The interface needs to send a to, but we must always use _msgSender()
        require(_msgSender() == _nftInterface, "Must be sent from an approved ERC721 Contract.");

        address owner = getOwnerbyNft(nft_index);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        require(to != owner, "ERC721: approval to current owner");
        // ERC-721 access control
        require(
            sender == owner || isApprovedForAll(owner, sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        // Set the approval.
        _nftApprovals[nft_index] = to;
        // Freeze it so we don't accidentally use it through the erc20 interface
        if (isLiquid(nft_index)) {
            _freeze(sender, nft_index);
        }
        return owner;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `tokenId` token must be owned by `from`.
     * - `recipient` cannot be the zero address.
     * - `nft_index` must be an owned or allowed nft index.
     */
    function _transferNft(
        address from,
        address to,
        uint24 nft_index
    ) internal virtual {
        require(getOwnerbyNft(nft_index) == from, "ERC721: transfer from incorrect owner");
        // Error case that would destory coins, _burn() is not allowed:
        require(to != address(0), "ERC721: transfer to the zero address");
        // Make sure this wallet isn't hit by OFAC.
        _beforeTokenTransfer(from, to, 1);
        // Do the deed.
        _transferNftsFrozen(from, to, nft_index);
        // extra check just in case - also ERC721 emits approval event
        // require(_nftApprovals[nft_index] == address(0), "NFT approval not reset");
    }

    /**
     * @dev See {IERC721-getApproved} - returns the address who is approved to transfer this NFT.
     *
     * Requirements:
     *
     * - `tokenId` Must be a minted and owned NFT.
     */
    function getApproved(uint24 nft_index) public view virtual returns (address) {
        require(getOwnerbyNft(nft_index) != address(0), "ERC721: approved query for nonexistent token");
        //Who is the most recent account to get approval.
        return _nftApprovals[nft_index];
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - approved` Turn approvals off and on for this operator.
     */
    function setApprovalForAllNfts(
        address sender,
        address operator,
        bool approved
    ) public virtual {
        require(_msgSender() == _nftInterface, "Must be sent from an approved ERC721 Contract.");

        require(sender != operator, "ERC721: approve to caller");
        // set operator approved for all NFTs
        _operatorApprovals[sender][operator] = approved;
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `nft_index`.
     *
     * Requirements:
     *
     * - `nft_index` must be frozend.
     */
    function _isApprovedOrOwnerNft(address spender, uint24 nft_index) internal view virtual returns (bool) {
        address owner = getOwnerbyNft(nft_index);
        require(owner != address(0), "ERC721: operator query for nonexistent token");
        return (spender == owner || getApproved(nft_index) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferNftFrom(
        address sender,
        address from,
        address to,
        uint24 nft_index
    ) public virtual {
        // Must be sent from the NFT interface
        require(_msgSender() == _nftInterface, "Must be sent from an approved ERC721 Contract.");
        // ERC-721 access control
        require(_isApprovedOrOwnerNft(sender, nft_index), "ERC721: transfer caller is not owner nor approved");
        // Make the transfer and notify the caller if it was a success
        _transferNft(from, to, nft_index);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint24 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address sender,
        address from,
        address to,
        uint24 tokenId,
        bytes memory _data
    ) private returns (bool) {
        // If it is a contract, then invoke the reciver to see if the coins were sent properly
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(sender, from, tokenId, _data) returns (bytes4 retval) {
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
     * @dev See {IERC721-safeTransferFrom} - _transferNft is always safe.
     */
    function safeTransferNftFrom(
        address sender,
        address from,
        address to,
        uint24 nft_index,
        bytes memory _data
    ) public virtual {
        // Make sure this call is coming from a trusted contract
        require(_msgSender() == _nftInterface, "Must be sent from an approved ERC721 Contract.");
        // ERC-721 access control
        require(_isApprovedOrOwnerNft(sender, nft_index), "ERC721: transfer caller is not owner nor approved");
        // Update the ledger:
        _transferNft(from, to, nft_index);
        // Require that the NFT was recived, or rollback the ledger:
        require(
            _checkOnERC721Received(sender, from, to, nft_index, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    //end of coin.

    /**
     * @dev Enforce deny list before the funds are transfered. This is enforcement of the OFAC controlls
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal virtual {
        // Make sure a transaction is coming and going to a good wallet.
        require(!_denylist[from], "Flake.art has blocked sender");
        require(!_denylist[to], "Flake.art has blocked receiver");
    }

    /**
     * @dev update NFT contract interface.
     */
    function setNFTInterface(address interfaceAddr) public onlyOwner returns (bool) {
        // What is our NFT interface address?
        _nftInterface = interfaceAddr;
        return true;
    }

    /**
     * @dev add addresses to denylist - OFAC controlls
     */
    function addToDenylist(address[] calldata addrs) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];
            _denylist[addr] = true;
        }

        emit AddedToDenylist(addrs);
        return true;
    }

    /**
     * @dev remove addresses from denylist - OFAC controlls
     */
    function removeFromDenylist(address[] calldata addrs) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];
            delete _denylist[addr];
        }

        emit RemovedFromDenylist(addrs);
        return true;
    }

    /**
     * @dev Allows the owner to designate a new tresury.
     */
    function setTreasury(address treasury) public onlyOwner returns (bool) {
        // Assign a new treasurer as a persistant member of this class contract.
        _treasury = treasury;
        emit UpdatedTreasury(treasury);
        return true;
    }

    // recover T's public address
    function _getMintSigner(
        address _account,
        uint24[] calldata _nft_indexes,
        bytes memory _signature
    ) internal pure returns (address) {
        // Use the treasury as the key.
        return keccak256(abi.encodePacked(_account, _nft_indexes)).toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @dev Assign ownership to a newly created NFT, in a frozen state.
     */
    function mintNft(
        address to,
        uint24[] calldata nft_indexes,
        bytes calldata signature
    ) public virtual returns (bool) {
        require(to != address(0), "ERC721: mint to the zero address");
        // nft count
        uint256 nftCount = nft_indexes.length;

        _beforeTokenTransfer(address(0), to, nftCount);
        // only callable with a signed request.
        require(_getMintSigner(to, nft_indexes, signature) == _treasury, "Error: Mint signature doesn't match");
        // Set unassigned coins to a new owner.
        for (uint256 i = 0; i < nftCount; i++) {
            // Unsigned cannot be negitive, the smallest is zero.
            // _addNft() can only be used for unowned tokens, this prevents replay attacks because the coin will be owned.
            require(_addNft(to, nft_indexes[i]));
        }
        _totalSupply += uint24(nftCount);
        // success
        // emit Transfer(address(0), to, (_totalSupply - nftCount));
        ShellNFT(_nftInterface).transferEventProxy(address(0), to, nft_indexes);
        return true;
    }

    /**
     * @dev Assign ownership to a newly created coin, in a liquid state.
     */
    function mintCoin(
        address to,
        uint24[] calldata nft_indexes,
        bytes calldata signature
    ) public virtual returns (bool) {
        require(to != address(0), "ERC20: mint to the zero address");
        uint256 nftCount = nft_indexes.length;

        _beforeTokenTransfer(address(0), to, nftCount);

        // only callable with a signed request.
        require(_getMintSigner(to, nft_indexes, signature) == _treasury, "Error: Mint signature doesn't match");
        // Set unassigned coins to a new owner.
        for (uint256 i = 0; i < nftCount; i++) {
            // Make sure we are minting an nft within the range.
            // require((nft_indexes[i] <= _maxSupply), "Error: NFT index too large.");
            // Unsigned cannot be negitive, the smallest is zero.
            // _addCoin() can only be used for unowned tokens, this prevents replay attacks because the coin will be owned.
            require(_addCoin(to, nft_indexes[i]));
        }
        _totalSupply += uint24(nftCount);
        // success
        emit Transfer(address(0), to, (_totalSupply - uint24(nftCount)));
        ShellNFT(_nftInterface).transferEventProxy(address(0), to, nft_indexes);
        return true;
    }

    /**
     * @dev Some tokens can be created based on demand. However, in.st is fininate accross all networks.
     */
    function mint(
        uint24 /*amount*/
    ) public view virtual {
        revert("Art Flake has a max supply of one million - mint() disabled see: mintCoin() and mintNft().");
    }

    /**
     * @dev Tokens must not be allowed to be destoryed, if one isn't needed any longer then the owner will take it back.
     */
    function burn(uint24 amount) public payable {
        // tokens cannot be destroyed, they are returned.
        transfer(owner(), amount);
    }

    /**
     * @dev Remove all approvals to an asset accross all interfaces.  Lock down the fort, keep your coins.
     */
    function removeAllApprovals(address operator) public {
        // Remove all allowences for this operator.
        uint256 nftCount = _OwnerToLiquidCoinMap[_msgSender()].length;
        // Make sure all NFT allowences are cleared
        for (uint256 i = 0; i < nftCount; i++) {
            if (_nftApprovals[_OwnerToLiquidCoinMap[_msgSender()][i]] != address(0)) {
                delete _nftApprovals[_OwnerToLiquidCoinMap[_msgSender()][i]];
            }
        }
        // remove ERC20 approvals:
        delete _allowances[_msgSender()][operator];
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SeaCoin.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ShellNFT is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    // Access Control Parent Contract
    address private _ledger;

    // Where we store our NFTs
    string private _baseURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    // _motherAddress might define in constructor
    constructor(
        address ledger_,
        string memory name_,
        string memory symbol_,
        string memory _uri
    ) {
        _ledger = ledger_;
        _name = name_;
        _symbol = symbol_;
        _baseURI = _uri;
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
     * @dev See {IERC165-supportsInterface}.
     */
    function transferEventProxy(
        address from,
        address to,
        uint24[] calldata tokenIds
    ) public virtual {
        require(msg.sender == _ledger, "ERC721: Only _ledger can trigger events");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit Transfer(from, to, uint256(tokenIds[i]));
        }
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return SeaCoin(_ledger).balanceOfNft(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = SeaCoin(_ledger).getOwnerbyNft(uint24(tokenId));
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
        require(ownerOf(tokenId) != address(0), "ERC721Metadata: URI query for nonexistent token");
        // Make sure the token is possilbe.
        if (tokenId <= SeaCoin(_ledger).maxSupply() && tokenId > 0) {
            // All flake.art coins are pre-mapped to our CDN, and populated upon minting.
            return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
        }
        return "";
    }

    /**
     * @dev Update the Base URI for computing {tokenURI}. Used to move to a differnt CDN
     *
     */
    function setBaseURI(string memory newURI) public onlyOwner {
        _baseURI = newURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function totalSupply() public view virtual returns (uint256) {
        // Only show number minted.
        return SeaCoin(_ledger).totalSupply();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = SeaCoin(_ledger).approveNft(_msgSender(), to, uint24(tokenId));
        if (owner != address(0)) {
            // Let others know of the sucessful call.
            emit Approval(owner, to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return SeaCoin(_ledger).getApproved(uint24(tokenId));
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        SeaCoin(_ledger).setApprovalForAllNfts(_msgSender(), operator, approved);
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return SeaCoin(_ledger).isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        SeaCoin(_ledger).transferNftFrom(_msgSender(), from, to, uint24(tokenId));
        // emit approval for compatibility with openzepplin
        emit Approval(from, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        SeaCoin(_ledger).safeTransferNftFrom(_msgSender(), from, to, uint24(tokenId), "");
        // emit approval for compatibility with openzepplin
        emit Approval(from, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data_
    ) public override {
        SeaCoin(_ledger).safeTransferNftFrom(_msgSender(), from, to, uint24(tokenId), data_);
        // emit approval for compatibility with openzepplin
        emit Approval(from, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     */
    function mint(
        address, /*to*/
        uint256 /*tokenId*/
    ) public view virtual {
        revert("Art Flake has a max supply of one million and is not mintable.");
    }

    /**
     * @dev sends tokenId to the owner of the contract.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     */
    function burn(uint256 tokenId) public virtual {
        // "Burned" NFTs are returned to the owner of the contract.
        SeaCoin(_ledger).transferNftFrom(_msgSender(), _msgSender(), owner(), uint24(tokenId));
        emit Transfer(_msgSender(), owner(), tokenId);
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