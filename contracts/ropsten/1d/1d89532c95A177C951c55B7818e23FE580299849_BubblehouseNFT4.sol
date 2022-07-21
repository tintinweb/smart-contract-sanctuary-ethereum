// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
interface IOpenSeaProxyRegistry {
    function proxies(address wallet) external view returns (address proxy);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract BubblehouseNFT4 is IERC165, IERC721, IERC721Metadata {

    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef; // keccak256(bytes("Transfer(address,address,uint256)"))

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to); // ERC2309

    // only non-obvious errors are returned; obvious error conditions just call revert()
    error TokenBurned();
    error TransferFromIncorrectOwner();
    error TransferToContractForbidden();
    error OverSupplyLimit();

    string private _name;
    string private _symbol;
    string private _baseMetadataURI;

    address private _contractOwner; // assigns minter and operator, and adjusts other global settings
    address private _minter; // the only entity that can mint
    address private _bubblehouseOperator; // implicitly approved to transfer from all wallets
    address private _openSeaProxyRegistryAddress; // implicitly approved to transfer from all wallets
   
    // Token state bit layout:
    // - [0..159]   `addr`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _tokenStates;
    uint256 private constant _BITMASK_BURNED = 1 << 224;
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;
    uint256 private constant _BITMASK_BURNED_AND_NEXT_INITIALIZED = (1 << 224) | (1 << 225);

    mapping(address => uint256) private _walletBalances;
    mapping(address => mapping(address => bool)) private _walletOperators;
    mapping(uint256 => address) private _tokenApprovals;
    uint256 private _stride;
    uint256 private _totalMinted = 0;
    uint256 private _burnCounter;
    uint256 private _supplyLimit;

    function totalMinted() external view returns (uint256) {
        return _totalMinted;
    }

    function totalSupply() external view returns (uint256) {
        unchecked {
            return _totalMinted - _burnCounter;
        }
    }
    modifier onlyContractOwner() {
        if (msg.sender != _contractOwner) {
            revert();
        }
        _;
    }

    constructor(string memory name_, string memory symbol_, uint64 supplyLimit_, uint64 stride_, uint64 premintQuantity_, address premintOwner_, address owner_, address minter_, address bubblehouseOperator_,  address openSeaProxyRegistryAddress_, string memory baseMetadataURI_) {
        _name = name_;
        _symbol = symbol_;
        _supplyLimit = supplyLimit_;
        _stride = stride_;
        if (owner_ == address(0)) {
            _contractOwner = msg.sender;
        } else {
            _contractOwner = owner_;
        }
        _minter = minter_;
        _bubblehouseOperator = bubblehouseOperator_;
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress_;
        _baseMetadataURI = baseMetadataURI_;
        if (premintQuantity_ != 0) {
            _premint(premintOwner_, premintQuantity_);
        }
    }


    // --- Inquiries ---

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        if (bytes(_symbol).length == 0) {
            return _name;
        } else {
            return _symbol;
        }
    }

    function supplyLimit() external view returns (uint256) {
        return _supplyLimit;
    }

    function stride() external view returns (uint256) {
        return _stride;
    }

    function balanceOf(address wallet) external view override returns (uint256) {
        if (wallet == address(0)) {
            revert();
        }
        return _walletBalances[wallet];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        _revertUnlessValidTokenID(tokenId);
        uint256 state = _tokenStateOf(tokenId);
        if ((state & _BITMASK_BURNED) != 0) {
            revert();
        }
        return address(uint160(state));
    }

    function baseTokenURI() external view returns (string memory) {
        return _baseMetadataURI;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        _revertUnlessValidTokenID(tokenId);
        return string.concat(_baseMetadataURI, intToString(tokenId));
    }

    function contractURI() external view returns (string memory) {
        return string.concat(_baseMetadataURI, "-1");
    }

    function internalRawTokenState(uint256 tokenId) external view returns (uint256) {
        return _tokenStates[tokenId];
    }
    function internalRawTokenStates(uint256 start, uint256 end) external view returns (uint256[] memory) {
        unchecked {
            if (start == 0) {
                start = 1; // prevents overflow when computing `end-start+1` below
            }
            if (end > _totalMinted) {
                end = _totalMinted;
            }
            if (end < start) {
                return new uint256[](0);
            }

            uint256[] memory result = new uint256[](end - start + 1);
            for (uint256 i = start; i <= end; ++i) {
                result[i - start] = _tokenStates[i];
            }
            return result;
        }
    }

    function internalResolvedTokenState(uint256 tokenId) external view returns (uint256) {
        return _tokenStateOf(tokenId);
    }
    function internalResolvedTokenStates(uint256 start, uint256 end) external view returns (uint256[] memory) {
        unchecked {
            if (start == 0) {
                start = 1; // prevents overflow when computing `end-start+1` below
            }
            if (end > _totalMinted) {
                end = _totalMinted;
            }
            if (end < start) {
                return new uint256[](0);
            }

            uint256 state = _tokenStateOf(start);

            uint256[] memory result = new uint256[](end - start + 1);
            for (uint256 i = start; i <= end; ++i) {
                uint256 prev = state;
                state = _tokenStates[i];
                if (state == 0) {
                    state = prev;
                }
                result[i - start] = state;
            }
            return result;
        }
    }

    function tokensOfOwnerIn(address wallet, uint256 start, uint256 end) external view returns (uint256[] memory) {
        unchecked {
            if (start == 0) {
                start = 1; // prevents overflow when computing `end-start+1` below
            }
            if (end > _totalMinted) {
                end = _totalMinted;
            }
            uint256 maxCount = _walletBalances[wallet];
            if (end < start || maxCount == 0) {
                return new uint256[](0);
            }
            uint256 range = end - start + 1;
            if (range < maxCount) {
                maxCount = range;
            }

            uint256[] memory tokenIds = new uint256[](maxCount);
            uint256 outIdx = 0;

            address currentOwner = address(0);
            uint256 state = _tokenStateOf(start);
            if ((state & _BITMASK_BURNED) == 0) {
                currentOwner = address(uint160(state));
            }

            for (uint256 i = start; i <= end && outIdx != maxCount; ++i) {
                state = _tokenStates[i];
                if (state != 0) {
                    if ((state & _BITMASK_BURNED) != 0) {
                        continue;
                    }
                    currentOwner = address(uint160(state));
                }
                if (currentOwner == wallet) {
                    tokenIds[outIdx++] = i;
                }
            }

            assembly { mstore(tokenIds, outIdx) } // shrink to actual size
            return tokenIds;
        }
    }


    // --- Mint, Transfer, Burn ---

    function mint(address to, uint256 quantity) external {
        if (msg.sender != _minter) revert();
        if (quantity == 0) revert();

        unchecked {
            if (to.code.length != 0) revert TransferToContractForbidden();
            uint256 oldTotalMinted = _totalMinted;
            uint256 newTotalMinted = oldTotalMinted + quantity;
            if (newTotalMinted > _supplyLimit) revert OverSupplyLimit();

            uint256 start = oldTotalMinted + 1;

            _walletBalances[to] += quantity;

            uint256 toMasked;
            uint256 newState;
            assembly {
                toMasked := and(to, _BITMASK_ADDRESS)
                newState := or(toMasked, shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1)))
            }
            if (toMasked == 0) revert();
            _tokenStates[start] = newState;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, start)

                let end := add(newTotalMinted, 1)
                for {
                    let tokenId := add(start, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }

            _totalMinted = newTotalMinted;
        }
    }

    function _premint(address to, uint256 quantity) private {
        if (quantity == 0) return;
        if (to == address(0)) revert();
        if (to.code.length != 0) revert TransferToContractForbidden();

        unchecked {
            uint256 oldTotalMinted = _totalMinted;
            uint256 newTotalMinted = oldTotalMinted + quantity;
            if (newTotalMinted > _supplyLimit) revert OverSupplyLimit();
            uint256 start = oldTotalMinted + 1;

            _walletBalances[to] += quantity;

            uint256 newState;
            assembly {
                newState := or(and(to, _BITMASK_ADDRESS), shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1)))
            }
            _tokenStates[start] = newState;

            emit ConsecutiveTransfer(start, start + quantity - 1, address(0), to);

            _totalMinted = newTotalMinted;
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata /*data*/) external override {
        transferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (to == address(0)) revert();
        if (to.code.length != 0) revert TransferToContractForbidden();
        _revertUnlessValidTokenID(tokenId);
        uint256 state = _tokenStateOf(tokenId);
        if ((state & _BITMASK_BURNED) != 0) revert TokenBurned();
        address tokenOwner = address(uint160(state));
        if (from != tokenOwner) revert TransferFromIncorrectOwner();
        _revertUnlessAllowedToManageToken(_actualSender(), tokenId, tokenOwner);
        _clearApproval(tokenId, tokenOwner);

        unchecked {
            _walletBalances[from] -= 1;
            _walletBalances[to] += 1;

            uint256 newState;
            assembly {
                newState := or(and(to, _BITMASK_ADDRESS), _BITMASK_NEXT_INITIALIZED)
            }
            _tokenStates[tokenId] = newState;

            // Fill in next token's data
            if ((state & _BITMASK_NEXT_INITIALIZED) == 0) {
                uint256 next = tokenId + 1;
                if (_tokenStates[next] == 0) {
                    if (next <= _totalMinted) {
                        _tokenStates[next] = state;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _revertUnlessValidTokenID(tokenId);
        uint256 state = _tokenStateOf(tokenId);
        if ((state & _BITMASK_BURNED) != 0) {
            return;
        }
        address tokenOwner = address(uint160(state));
        _revertUnlessAllowedToManageToken(_actualSender(), tokenId, tokenOwner);
        _clearApproval(tokenId, tokenOwner);

        unchecked {
            _walletBalances[tokenOwner] -= 1;
            assembly {
                state := or(state, _BITMASK_BURNED_AND_NEXT_INITIALIZED)
            }
            _tokenStates[tokenId] = state;
            _burnCounter += 1;
        }

        emit Transfer(tokenOwner, address(0), tokenId);
    }


    // --- Approvals ---
    
    function approve(address to, uint256 tokenId) external override {
        _revertUnlessValidTokenID(tokenId);
        uint256 state = _tokenStateOf(tokenId);
        if ((state & _BITMASK_BURNED) != 0) revert TokenBurned();
        address tokenOwner = address(uint160(state));
        address actor = _actualSender();
        _revertUnlessAllowedToManageToken(actor, tokenId, tokenOwner);
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        _revertUnlessValidTokenID(tokenId);
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        address actor = _actualSender();
        if (actor == operator) {
            revert();
        }
        _walletOperators[actor][operator] = approved;
        emit ApprovalForAll(actor, operator, approved);
    }

    function isApprovedForAll(address wallet, address operator) external view override returns (bool) {
        return _walletOperators[wallet][operator];
    }

    function _clearApproval(uint256 tokenId, address tokenOwner) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
            emit Approval(tokenOwner, address(0), tokenId);
        }
    }


    // --- Marketplaces ---

    function isOpenSeaOperator(address actor, address wallet) private view returns (bool) {
        if (_openSeaProxyRegistryAddress == address(0)) {
            return false;
        }
        IOpenSeaProxyRegistry proxyRegistry = IOpenSeaProxyRegistry(_openSeaProxyRegistryAddress);
        return (address(proxyRegistry.proxies(wallet)) == actor);
    }


    // -- Access checks ---

    function _revertUnlessValidTokenID(uint256 tokenId) private view {
        if (tokenId < 1) {
            revert();
        }
        if (tokenId > _totalMinted) {
            revert();
        }
    }

    // assumes token ID is valid
    function _revertUnlessAllowedToManageToken(address actor, uint256 tokenId, address wallet) private view {
        if (actor == wallet) {
            return;
        }
        if (actor == _bubblehouseOperator) {
            if (_bubblehouseOperator != address(0)) {
                return;
            }
        }
        if (_walletOperators[wallet][actor]) {
            return;
        }
        if (isOpenSeaOperator(actor, wallet)) {
            return;
        }
        if (_tokenApprovals[tokenId] == actor) {
            return;
        }
        revert();
    }


    // --- Sparse Packed Token Info ---

    function _tokenStateOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;
        unchecked {
            uint256 state = _tokenStates[curr];
            // There will always be a non-zero state before any zero state.
            while (state == 0) {
                --curr;
                state = _tokenStates[curr];
            }
            return state;
        }
    }


    // --- Admin Stuff ---

    function rename(string calldata name_, string calldata symbol_) external onlyContractOwner {
        _name = name_;
        _symbol = symbol_;
    }

    function setBaseMetadataURI(string calldata newBaseURI) external onlyContractOwner {
        _baseMetadataURI = newBaseURI;
    }

    function replaceContractOwner(address newOwner) external onlyContractOwner {
        if (newOwner == address(0)) {
            revert();
        }
        address oldOwner = _contractOwner;
        if (newOwner == oldOwner) {
            return;
        }
        _contractOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function bubblehouseOperator() external view returns (address) {
        return _bubblehouseOperator;
    }
    function replaceBubblehouseOperator(address newOperator) external onlyContractOwner {
        if (_bubblehouseOperator == address(0)) {
            revert();
        }
        if (newOperator == address(0)) {
            revert();
        }
        _bubblehouseOperator = newOperator;
    }
    // Irevocably disables Bubblehouse operator priviledges. Wallets will need operator approvals
    // to be managed by the platform after this.
    function burnBubblehouseOperator() external onlyContractOwner {
        _bubblehouseOperator = address(0);
    }

    function setOpenSeaProxyRegistryAddress(address addr) external onlyContractOwner {
        _openSeaProxyRegistryAddress = addr;
    }

    function owner() external view returns (address) {
        return _contractOwner;
    }

    function minter() external view returns (address) {
        return _minter;
    }
    function replaceMinter(address newMinter) external onlyContractOwner {
        if (_minter == address(0)) {
            revert();
        }
        if (newMinter == address(0)) {
            revert();
        }
        _minter = newMinter;
    }
    // Irevocably disables minter priviledges. Nothing can be minted after this.
    function burnMinter() external onlyContractOwner {
        _minter = address(0);
    }

    function decreaseSupplyLimit(uint64 supplyLimit_) external onlyContractOwner {
        if (supplyLimit_ >= _supplyLimit) revert();
        _supplyLimit = supplyLimit_;
    }


    // --- Utils ---
    
    // TODO: handle metatransactions in the future if we need to.
    function _actualSender() private view returns (address) {
        return msg.sender;
    }

    // From @openzeppelin/contracts/utils/Strings.sol
    function intToString(uint256 value) private pure returns (string memory) {
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

}