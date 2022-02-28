/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}


contract _8BitMFers is ERC721("8Bit-mfers", "bmfers") {

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */
    address public owner = msg.sender;

    uint256 constant MINT_FEE = 0.0099 ether; 
    
    uint256 constant MAX_GIVEAWAY_SUPPLY = 500;

    uint256 constant maxMintPerWallet = 25;

    uint256 constant MAX_SUPPLY = 6969;

    address constant MF_TEAM = address(0xA0c8041d9e225cba96089778C0cA3bf9fb7AFb7D); // change this to your address

    string constant unrevealedURI = "https://ipfs.io/ipfs/QmTYzJLzsaCqpceocDAuU2vsmZxRgNJSbvhrEZ8PcMLDAF";

    /* -------------------------------------------------------------------------- */
    /*                                MUTABLE STATE                               */
    /* -------------------------------------------------------------------------- */

    uint256 public giveawaySupply;

    uint256 public totalSupply;

    uint256 public revealedSupply;

    string public revealedURI;

    /* -------------------------------------------------------------------------- */
    /*                               MF_TEAM_METHODS                              */
    /* -------------------------------------------------------------------------- */

    function giveaway(address account, uint256 amount) external {
        // make sure no more than max supply can be minted
        require(totalSupply + amount <= MAX_SUPPLY);
        // make sure only MF team can call this method
        require(msg.sender == MF_TEAM);
        // make sure max giveaway supply is satisfied
        require(giveawaySupply + amount < MAX_GIVEAWAY_SUPPLY);

        for (uint i; i < amount; i++) {
            // increase totalSupply by 1
            totalSupply++;
            // increase giveawaySupply by 1
            giveawaySupply++;
            // mint user 1 nft
            _mint(account, totalSupply);
        }
    }

    function withdraw(address account, uint256 amount) external {
        // make sure only MF team can call this method
        require(msg.sender == MF_TEAM);
        
        // transfer amount to account
        payable(account).transfer(amount);
    }

    function reveal(string memory updatedURI, uint256 _revealedSupply) external {
        // make sure only MF team can call this method
        require(msg.sender == MF_TEAM);

        require(revealedSupply <= MAX_SUPPLY);

        revealedSupply = _revealedSupply;

        revealedURI = updatedURI;
    }
    /* -------------------------------------------------------------------------- */
    /*                               PUBLIC METHODS                               */
    /* -------------------------------------------------------------------------- */


    function mint(address account) external payable {
        //tokenbalance check
        require(balanceOf[account] + 1 <= maxMintPerWallet);
        // if supply is less than or equal to 500 allow user to mint free
        if (totalSupply > 500) require(msg.value >= MINT_FEE);


        require(totalSupply + 1 <= MAX_SUPPLY);
        totalSupply++;

        _mint(account, totalSupply);

    }

    function batchMint(address account, uint256 amount) external payable {
        //tokenbalance check
        require(balanceOf[account] + 1 <= maxMintPerWallet);

        require(totalSupply + amount <= MAX_SUPPLY);

  
        if (totalSupply > 500) require(msg.value >= MINT_FEE * amount);

        for (uint i; i < amount; i++) {

            totalSupply++;

            _mint(account, totalSupply);

        }
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {

        if (tokenId > revealedSupply) return unrevealedURI;

        return string(abi.encodePacked(revealedURI, "/", _toString(tokenId), ".json"));
    }


    /* -------------------------------------------------------------------------- */
    /*                              INTERNAL METHODS                              */
    /* -------------------------------------------------------------------------- */

    function _toString(uint256 value) internal pure returns (string memory) {
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