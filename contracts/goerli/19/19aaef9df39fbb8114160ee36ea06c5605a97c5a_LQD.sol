/*

LiquidToken standard is compatible with all the ERC721 marketplaces and apps that fully
support ERC721. It is also compatible with the ERC20 standard except for events Transfer 
and Approval which are token_Transfer and token_Approval, due to overlapping with ERC721, and
the function transferFrom and approve which are token_transferFrom and token_approve for the
same reason.

The flag returned by is_liquid() method is used by any compatible swap (or swap that want to
become compatible easily) to know which methods to use to swap the token. If the flag is true,
the swap will use the methods token_transferFrom and token_approve. If the flag is false or 
non existent, the swap will use the methods transferFrom and approve like usual.

This is not needed for NFTs (like on OpenSea or Rarible) because the methods changed are changed
in the ERC20 part and remains available like usual for the ERC721 part.
The design decision is made to guarantee ERC721 retrocompability while providing an easy
to use way to integrate ERC20 compatibility in any swap.

*/

// SPDX-License-Identifier: CC-BY-ND-4.0

// SECTION Development log

// TODO find a way to bulk transfer a set of ids
// Ideas: 
// Two mechanisms, one for a set of sequential ids and one for a set of sparse ids
// TODO find a way to keep approve(), transferFrom(), Transfer e Approve for ERC721 and ERC20
// Ideas:
// Using a custom swap just for tokens or nfts to keep compatibility with either OS or Uniswap

// !SECTION Development log

pragma solidity ^0.8.16;

import "./helpers.sol";

interface LiquidToken {
    // LiquidToken
    function is_liquid() external view returns (bool);
    // ERC20
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getowner() external view returns (address);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint);
    function token_approve(address spender, uint amount) external returns (bool);
    function token_transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event token_Transfer(address indexed from, address indexed to, uint value);
    event token_Approval(address indexed owner, address indexed spender, uint value);

    // ERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view 
                                 returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view 
                              returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;
    function mint(uint _amount) external payable;

}

// SECTION Contract

contract LQD is LiquidToken {
    // ANCHOR Bitwise boolean replacement
    using bitwise_boolean for uint; 
    using strings_evolved for uint;

    // ANCHOR Boolean flags as uint8 (0 to 255)
    // 0: isMintable
    uint public flags;
    // 0: isOwner
    // 1: isAuth
    // 2: isWhitelisted
    // 3: isBlacklisted
    mapping(address => uint) public actor_flags;

    // ANCHOR Protection methods
    modifier onlyOwner() {
        if (!(actor_flags[msg.sender].check_state(0))) revert("LQD: Not owner");
        _;
    }
    modifier onlyAuth() {
        if (!(actor_flags[msg.sender].check_state(1))) revert("LQD: Not auth");
        _;
    }
    function isWhitelisted(address _address) public view returns(bool) {
        return actor_flags[_address].check_state(2);
    }
    function isBlacklisted(address _address) public view returns(bool) {
        return actor_flags[_address].check_state(3);
    }
    bool locked;
    modifier safe() {
        if (locked) revert("LQD: Reentrant");
        locked = true;
        _;
        locked = false;
    }
    receive() external payable {}
    fallback() external payable {}

    // ANCHOR Properties
    uint public treasury_balance;
    uint public dev_balance;
    uint constant MAX_UINT = 2**256 - 1;
    string public name = "Liquid Token";
    string public symbol = "LQD";
    uint8 public _decimals = 0;
    address public owner;
    address public router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public factory_address;
    address public pair_address;
    IUniswapRouter02 public router;
    IUniswapFactory public factory;
    IUniswapV2Pair public pair;

    // ANCHOR ERC20 Properties
    mapping(address => mapping(address => uint)) public _allowances;
    mapping(address => uint) public _balances;
    // Circulating supply
    uint public _totalSupply = 200; // 10.000
    // Taxes in percentages
    uint8 public buy_tax = 3;
    uint8 public sell_tax = 3;
    uint8 public transfer_tax = 3;
    // Percentages distributed to the treasury
    // The remains is dev_fee
    uint8 public treasury_fee = 20;
    // Swap treshold
    uint public swap_treshold = (_totalSupply * 1 / 1000); // 0.1 %
    // Amount of collected taxes
    uint tax_amount;

    // ANCHOR ERC721 Properties
    // Token URI
    string public _tokenURI;
    // Max mintable tokens
    uint public maxMintable = 5;
    // Max tokens in circulation
    uint public maxSupply = _totalSupply;
    // Price for a single mint
    uint public mintPrice = 0.01 ether;
    // Last id minted
    uint public id_head;
    // Who owns a specific index?
    mapping(uint => address) public id_to_owner; 
    // Which ids does a specific owner own?
    mapping(address => uint[]) public owner_to_ids; 
    // Which index does a specific owner have for a specific id?
    mapping(uint => mapping(address => uint)) public owner_to_ids_index; 

    // ANCHOR Constructor
    constructor() {
        // Ownerize
        owner = msg.sender;
        // Set owner and auth flags
        actor_flags[owner].set_true(0);
        actor_flags[owner].set_true(1);
        // Initialize router, factory and pair addresses
        router = IUniswapRouter02(router_address);
        factory_address = router.factory();
        factory = IUniswapFactory(factory_address);
        pair_address = factory.getPair(router.WETH(), address(this));
        pair = IUniswapV2Pair(pair_address);
        // Mint initial tokens (unchecked saves a lot of gas)
        _balances[owner] = _totalSupply;
        unchecked {
            id_head = _totalSupply - 1;
            for (uint i = 0; i < _totalSupply; i++) {
                id_to_owner[i] = owner;
                owner_to_ids[owner].push(i);
                owner_to_ids_index[i][owner] = owner_to_ids[owner].length - 1;
            }
        }
    }


    // SECTION Token Methods

    // SECTION Transfers
    function transfer(address recipient, uint amount) public safe override returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) internal {
        if(_balances[from] < amount) revert("Insufficient balance");
        if(isBlacklisted(from) || isBlacklisted(to)) revert("Blacklisted");
        if(isWhitelisted(from) || isWhitelisted(to)) {
            _whitelistTransfer(from, to, amount);
        }
        _taxedTransfer(from, to, amount);
    }

    function _whitelistTransfer(address from, address to, uint amount) internal {
        _balances[from] -= amount;
        _balances[to] += amount;
        //emit token_Transfer(from, to, amount);
        emit Transfer(from, to, amount);
    }

    function _taxedTransfer(address from, address to, uint amount) internal {
        // Type determination
        // 0 = buy
        // 1 = sell
        // 2 = transfer
        uint8 transfer_type;
        if(from == pair_address || from == router_address) {
            transfer_type = 0;
        } else if(to == pair_address || to == router_address) {
            transfer_type = 1;
        } else {
            transfer_type = 2;
        }
        // Actual tax determination
        uint local_tax;
        if(transfer_type == 0) {
            local_tax = buy_tax;
        } else if(transfer_type == 1) {
            local_tax = sell_tax;
        } else {
            local_tax = transfer_tax;
        }
        // Tax calculation and remains
        uint taxed_amount = amount - (amount * local_tax / 100);
        tax_amount += amount - taxed_amount;
        // Tax swap on sells
        if(tax_amount >= swap_treshold) {
            _swapTaxes(amount);
        }
        // Actual transfer
        _balances[from] -= amount;
        _balances[to] += taxed_amount;
        _balances[address(this)] += tax_amount;
        // REVIEW event Transfer is used for both NFT and Token transfers. Will it work?
        //emit token_Transfer(from, address(this), tax_amount);
        //emit token_Transfer(from, to, taxed_amount);
        emit Transfer(from, address(this), tax_amount);
        emit Transfer(from, to, taxed_amount);
        // REVIEW Plain nft transfer, probably high gas usage
        // Transferring to recipient
        for (uint i = 0; i < taxed_amount; i++) {
            uint index_to_take = owner_to_ids[from].length -1;
            uint id_to_transfer = owner_to_ids[from][index_to_take];
            transferNFT(from, to, id_to_transfer);
        }
        // Transferring taxes
        for (uint i = 0; i < tax_amount; i++) {
            uint index_to_take = owner_to_ids[from].length -1;
            uint id_to_transfer = owner_to_ids[from][index_to_take];
            transferNFT(from, address(this), id_to_transfer);
        }
    }

    // !SECTION Transfers

    // SECTION Taxes

    function _swapTaxes(uint tx_amount) internal {
        uint to_swap = tax_amount;
        // Avoid dumps
        if (to_swap > tx_amount) {
            to_swap = tx_amount;
        }
        // Swap
        uint pre_balance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        // REVIEW theoretically the router should call transfer anyway
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            to_swap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint post_balance = address(this).balance;
        uint swapped = post_balance - pre_balance;
        // Take no action if swapped is 0
        if (swapped == 0) {
            return;
        }
        // Tax distribution
        uint treasury_amount = (swapped * treasury_fee) / 100;
        uint dev_amount = swapped - treasury_amount;
        treasury_balance += treasury_amount;
        dev_balance += dev_amount;
    }

    function withdraw_dev() public onlyAuth {
        (bool success, ) = payable(msg.sender).call{value: dev_balance}("");
        if (success) {
            dev_balance = 0;
        } else {
            revert("Withdraw failed");
        }
    }

    function withdraw_treasury() public onlyAuth {
        (bool success, ) = payable(msg.sender).call{value: treasury_balance}("");
        if (success) {
            treasury_balance = 0;
        } else {
            revert("Withdraw failed");
        }
    }

    // !SECTION Taxes

    function getowner() public view override returns (address) {
        return owner;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function allowance(address _owner, address spender) public view override returns (uint) {
        if (spender==address(this)) {
            return MAX_UINT;
        }
        return _allowances[_owner][spender];
    }

    function token_approve(address spender, uint amount) public safe override returns(bool) {
        _allowances[msg.sender][spender] = amount;
        // emit Approval(msg.sender, spender, amount);
        emit token_Approval(msg.sender, spender, amount);
        return true;
    }

    function token_transferFrom(address sender, address recipient, uint amount) 
                                public safe override returns (bool) {
        if(_allowances[sender][msg.sender] < amount) {
            revert("Not enough allowance");
        }
        _allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    // !SECTION Token Methods

    // SECTION NFT Methods

    function mint(uint _amount) public safe override payable {
        if(!flags.check_state(0)) revert("Not mintable");
        if(_amount > maxMintable) revert("Too many tokens to mint");
        if(id_head + _amount > maxSupply) revert("Too many tokens in circulation");
        if(msg.value <= (mintPrice * _amount)) revert("Not enough ETH");
        if (_amount == 0) revert MintZeroQuantity();
        _mint(msg.sender, _amount);
    }

    function transferNFT(address from, address to, uint id) internal {
        delete owner_to_ids[from][owner_to_ids_index[id][from]];
        owner_to_ids[to].push(id);
        owner_to_ids_index[id][to] = owner_to_ids[to].length - 1;
        id_to_owner[id] = to;
        emit Transfer(from, to, id);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string.concat(_tokenURI, "/", tokenId.uint_to_string());
    }

    function setTokenURI(string memory uri) public onlyAuth {
        _tokenURI = uri;
    }

    // SECTION Flag settings

    function setMintable(bool _mintable) public onlyOwner {
        if (_mintable) {
            flags = flags.set_true(0);
        } else {
            flags = flags.set_false(0);
        }
    }

    // !SECTION Flag settings

    // ANCHOR ERC721 STORAGE

    // Array which maps token ID to address (index is tokenID)
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ANCHOR ERC165 LOGIC

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    // ANCHOR ERC721ENUMERABLE LOGIC

    function totalSupply() public view override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * Dont call this function on chain from another smart contract, since it can become quite expensive
     */
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view override 
                                 returns (uint256 tokenId) {
        if (index >= balanceOf(_owner)) revert OwnerIndexOutOfBounds();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; tokenId < qty; tokenId++) {
                if (_owner == ownerOf(tokenId)) {
                    if (count == index) return tokenId;
                    else count++;
                }
            }
        }

        revert UnableGetTokenOwnerByIndex();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }

    // ANCHOR ERC721 LOGIC

    /**
     * @dev Iterates through _owners array, returns balance of address
     * It is not recommended to call this function from another smart contract
     * as it can become quite expensive -- call this function off chain instead.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        if (_owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < qty; i++) {
                if (_owner == ownerOf(i)) {
                    count++;
                }
            }
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; ; tokenId++) {
                if (_owners[tokenId] != address(0)) {
                    return _owners[tokenId];
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address _owner = ownerOf(tokenId);
        if (to == _owner) revert ApprovalToCurrentOwner();

        if (msg.sender != _owner && !isApprovedForAll(_owner, msg.sender)) revert ApprovalCallerNotOwnerNorApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(_owner, to, tokenId);
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
        if (operator == msg.sender) revert ApproveToCaller();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if(operator==address(this)) {
            return true;
        }
        return _operatorApprovals[_owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        bool isApprovedOrOwner = (msg.sender == from ||
            msg.sender == getApproved(tokenId) ||
            msg.sender == address(this) ||
            isApprovedForAll(from, msg.sender));
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        // delete token approvals from previous owner
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        // if token ID below transferred one isnt set, set it to previous owner
        // if tokenid is zero, skip this to prevent underflow
        if (tokenId > 0 && _owners[tokenId - 1] == address(0)) {
            _owners[tokenId - 1] = from;
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        safeTransferFrom(from, to, id, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        transferFrom(from, to, id);

        if (!_checkOnERC721Received(from, to, id, data)) revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _owners.length;
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
        if (to.code.length == 0) return true;

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    // ANCHOR INTERNAL MINT LOGIC

    /**
     * @dev check if contract confirms token transfer, if not - reverts
     * unlike the standard ERC721 implementation this is only called once per mint,
     * no matter how many tokens get minted, since it is useless to check this
     * requirement several times -- if the contract confirms one token,
     * it will confirm all additional ones too.
     * This saves us around 5k gas per additional mint
     */
    function _safeMint(address to, uint256 qty) internal {
        _safeMint(to, qty, '');
    }

    function _safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) internal {
        _mint(to, qty);

        if (!_checkOnERC721Received(address(0), to, _owners.length - 1, data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    function _mint(address to, uint256 qty) internal {
        // Production and minting
        // Cannot realistically overflow, since we are using uint
        unchecked {
            for(uint i = id_head; i < (id_head + qty); i++) {
                id_to_owner[id_head] = to;
                owner_to_ids[to].push(id_head);
                owner_to_ids_index[id_head][to] = owner_to_ids[to].length - 1;
                emit Transfer(address(0), to, id_head);
            }
            // Updating id_head in a single line to save gas
            id_head += qty;
            // Token transfer sync
            _balances[msg.sender] += qty;
        }
        emit Transfer(address(0), msg.sender, qty);
    }

    function _mintOne(address to) internal returns (uint) {
        if (to == address(0)) revert MintToZeroAddress();
        
        uint256 _currentIndex = _owners.length;

        // set last index to _owners.length as is always +1 from the previous index (arrays starts with 0 and length starts with 1)
        _owners.push(to);
        emit Transfer(address(0), to, _currentIndex);
        return(_currentIndex);
    }
 
   // !SECTION NFT Methods

   // SECTION LiquidToken Methods
   // NOTE This is necessary to communicate to compatible swaps how to use this contract
   // If a swap encounter this method as true knows that:
   // - The transfer event is event token_Transfer  
   // - The approve event is event token_Approval
   // - The transferFrom method is token_transferFrom(address from, address to, uint256 value)
   // - the approve method is token_approve(address from, address to, uint256 value)
   function is_liquid() public pure returns (bool) {
    return true;
   }
   // !SECTION LiquidToken Methods

   // SECTION On Chain Metadata
    
    // TODO On chain metadata

   // !SECTION On Chain Metadata

}

// !SECTION Contract