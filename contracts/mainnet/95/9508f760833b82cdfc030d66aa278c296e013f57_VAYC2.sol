/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// This file is forked from Solmate v6,
/// We stand on the shoulders of giants
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
contract VAYC2 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/
    string private constant NOT_LIVE = "Sale not live";
    string private constant INCORRECT_PRICE = "Gotta pay right money";
    string private constant MINTED_OUT = "Max supply reached";
    string private constant FROZEN = "DATA_FROZEN";
    string private constant MIGRATED = "MIGRATION_OVER";

    string private token_metadata = "ipfs://QmUp2pBkqiGhdztfs5ym3AGttA5L8JLAUEPRawEKinRVcJ/";

    string public name;
    string public symbol;

    address public owner;
    uint16 public totalSupply;
    uint16 public counter = 0;
    uint16 public constant  MAX_SUPPLY =  10000; // only first 10000 were minted

    bool public saleMode = false;
    bool public market_frozen = false;
    bool public metadata_frozen = false;
    bool public migration_over = false;
    uint8 public giveawaysMinted = 0;
    address public market = address(0); //initialize to an address nobody controls
    uint256 public constant COST_MAYC =   0.042069 ether;
    uint256 public constant COST_PUBLIC = 0.069420 ether;
    uint8 constant MAX_MINT = 10;
    uint8 constant GIVEAWAY_LIMIT = 100;

    IERC721 private MAYC = IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
    IERC721 private BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC721 private BAKC = IERC721(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623);
    IERC721 private OLD_VAYC = IERC721(0x99FE9b46e8e2559EAc3c7BD5dd8f55238D89FBD0);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              ERC721/165/173 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external {
        address tokenOwner = ownerOf[id];

        require(msg.sender == tokenOwner || isApprovedForAll[tokenOwner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
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
    ) external {
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
    ) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165 interfaces
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721 tokens
            interfaceId == 0x7f5828d0 || // ERC173 Interface ID for ERC173 ownership
            interfaceId == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       VAYC SPECIFIC LOGIC 
    //////////////////////////////////////////////////////////////*/


    //
    // Modifiers
    //

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier duringMigration() {
        require(migration_over == false, MIGRATED);
        _;
    }

    modifier duringSale() {
        require(saleMode == true, NOT_LIVE);
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function setMarket(address _market) external onlyOwner {
        require(market_frozen == false, FROZEN);
        market_frozen = true;
        market = _market;
    }

    function saleToPause() external onlyOwner {
        saleMode = false;
    }

    function saleToPublic() external onlyOwner {
        saleMode = true;
    }

    function withdraw(uint amount) external onlyOwner {
        if(amount == 0) {
            payable(owner).transfer(address(this).balance);
        } else {
            payable(owner).transfer(amount);
        }
    }

    //
    // Minting
    //

    function mintPublic(uint16 num) external payable duringSale {
        require(msg.value == COST_PUBLIC * num, INCORRECT_PRICE);
        _mintY(num);
    }

    function mintWL(uint16 num, uint tokenId) external payable duringSale {
        bool baycFan =
            (msg.sender == MAYC.ownerOf(tokenId)) ||
            (msg.sender == BAYC.ownerOf(tokenId)) ||
            (msg.sender == BAKC.ownerOf(tokenId));
        require(baycFan, "Not whitelisted");
        require(msg.value == COST_MAYC * num, INCORRECT_PRICE);
        _mintY(num);
    }

    function mintGiveaway(uint8 num) external onlyOwner {
        require(giveawaysMinted < GIVEAWAY_LIMIT, "No more giveaways");
        giveawaysMinted += num;
        _mintY(num);
    }


    function _mintY(uint16 num) internal {
        require(num <= MAX_MINT, "Max 10 per TX");
        require(totalSupply + num < MAX_SUPPLY, MINTED_OUT);
        require(msg.sender.code.length == 0, "Hack harder bot master"); // bypassable, but raises level of effort
        uint id = counter;
        uint num_already_minted = 0;
        while(num_already_minted < num){
            if (ownerOf[id] == address(0)) {
                ownerOf[id] = msg.sender;
                emit Transfer(address(0), msg.sender, id);
                num_already_minted += 1;
            }
            id += 1;
        }
        unchecked {
            balanceOf[msg.sender] += num;
            counter = uint16(id);
            totalSupply = totalSupply + num;
        }
    }

    //
    // Migration logic
    //

    function _migrateTo(uint id, address person) internal {
        ownerOf[id] = person;
        emit Transfer(address(0), msg.sender, id);
        balanceOf[person] += 1;
    }

    function endMigration() public onlyOwner {
        migration_over = true;
    }

    function setMigrationSupply(uint16 _supply, uint16 _counter) public onlyOwner duringMigration {
        totalSupply = _supply;
        counter = _counter;
    }

    function migrateByHand(uint[] calldata tokenIds) public onlyOwner duringMigration {
        for (uint i; i < tokenIds.length; i++) {
            _migrateTo(tokenIds[i], OLD_VAYC.ownerOf(tokenIds[i]));
        }
    }

    function migrateBulk(uint16 start, uint16 end) public onlyOwner duringMigration {
        for (uint16 i = start; i < end; i++) {
            _migrateTo(i, OLD_VAYC.ownerOf(i));
        }
    }


    //
    // TokenURI logic
    //

    function uintToString(uint256 value) internal pure returns (string memory) {
        // stolen from OpenZeppelin Strings library
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
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

    function setTokenMetadata(string calldata url) public onlyOwner {
        require(metadata_frozen == false, FROZEN);
        metadata_frozen = true;
        token_metadata = url;
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        if(ownerOf[id] == address(0))
            return "";
        return string(abi.encodePacked(string(abi.encodePacked(token_metadata, uintToString(id))), ".json"));
    }

    //
    // Market Integration
    //

    function marketTransferFrom(address from, address to, uint256 id) external {
        require(msg.sender == address(market), "INVALID_CALLER");
        require(to != address(0), "INVALID_RECIPIENT");
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

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