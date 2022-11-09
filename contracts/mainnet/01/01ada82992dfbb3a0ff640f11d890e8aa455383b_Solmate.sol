/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// File src/solmate/ERC721.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), 'NOT_MINTED');
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), 'ZERO_ADDRESS');

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            'NOT_AUTHORIZED'
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], 'WRONG_FROM');

        require(to != address(0), 'INVALID_RECIPIENT');

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            'NOT_AUTHORIZED'
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ''
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            'UNSAFE_RECIPIENT'
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            'UNSAFE_RECIPIENT'
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), 'INVALID_RECIPIENT');

        require(_ownerOf[id] == address(0), 'ALREADY_MINTED');

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), 'NOT_MINTED');

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ''
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            'UNSAFE_RECIPIENT'
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            'UNSAFE_RECIPIENT'
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}


// File src/ProxyRegistry.sol

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
    mapping(address => bool) public contracts;
}


// File src/Solmate.sol

// ERC721A so we can make approve function virtual


contract Solmate is ERC721 {
    address private _owner;
    string public baseURI;
    uint256 public currentTokenId;
    uint256 public maxSupply = 1_000;

    // pauses transfers and sales
    // minting and burning are always allowed
    bool private _paused = true;

    // authorised Operators list
    address[] private authorisedOperators;

    // madworld marketplace proxy registry
    address public proxyRegistryAddress =
        0x8DEeC50d7d92911c40574700F7A51ee5130857EE;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        _owner = msg.sender;
    }

    // MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == _owner, 'CALLER_NOT_OWNER');
        _;
    }

    modifier transferActive() {
        require(!_paused, 'TRANSFER_PAUSED');
        _;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPaused(bool paused) external onlyOwner {
        _paused = paused;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setProxyRegistryAddress(address _proxyRegistry)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistry;
    }

    // OWNERSHIP

    function transferOwnership(address to) external onlyOwner {
        require(_owner != to, 'OWNER_SET');
        _owner = to;
    }

    // MINT

    function batchMint(address[] memory receivers) external onlyOwner {
        require(currentTokenId + receivers.length <= maxSupply, 'MAX_SUPPLY');

        uint256 newTokenId;

        for (uint8 i = 0; i < receivers.length; i++) {
            newTokenId = ++currentTokenId;
            _safeMint(receivers[i], newTokenId);
        }
    }

    // ERC721

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(ownerOf(tokenId) != address(0), 'NON_EXISTENT_TOKEN');

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : '';
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        ProxyRegistry registry = ProxyRegistry(proxyRegistryAddress);

        if (approved) {
            require(
                isAuthorisedOperator(operator) ||
                    address(registry.proxies(_msgSender())) == operator,
                'UNAUTHORISED_OPERATOR'
            );
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public override {
        if (to != address(0)) {
            ProxyRegistry registry = ProxyRegistry(proxyRegistryAddress);

            require(
                isAuthorisedOperator(to) ||
                    address(registry.proxies(_msgSender())) == to,
                'UNAUTHORISED_OPERATOR'
            );
        }
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override transferActive {
        super.transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override transferActive {
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual override transferActive {
        super.safeTransferFrom(from, to, id, data);
    }

    // OPERATOR AUTHORISATION

    function addAuthorisedOperator(address[] calldata operators)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < operators.length; i++) {
            authorisedOperators.push(operators[i]);
        }
    }

    function removeOperator(address operator) external onlyOwner {
        address[] memory filteredOperators;
        uint256 count = 0;

        for (uint256 i = 0; i < authorisedOperators.length; i++) {
            if (authorisedOperators[i] != operator) {
                filteredOperators[count] = authorisedOperators[i];
                count++;
            }
        }

        authorisedOperators = filteredOperators;
    }

    function isAuthorisedOperator(address operator) public view returns (bool) {
        for (uint256 i = 0; i < authorisedOperators.length; i++) {
            if (operator == authorisedOperators[i]) {
                return true;
            }
        }

        return false;
    }

    // UTIL FUNCTIONS

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     *   from ERC721A
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}